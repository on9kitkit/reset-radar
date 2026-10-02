import Foundation
import Security
import CryptoKit
import Darwin

struct XNewsPost: Codable {
    let id:String
    let username:String
    let text:String
    let createdAt:Date
    var sourceURL:String { "https://x.com/\(username.lowercased())/status/\(id)" }
}

struct XNewsSnapshot {
    let fetchedAt:Date
    let windowStart:Date
    let windowEnd:Date
    let accounts:[String]
    let posts:[XNewsPost]
    let coverageComplete:Bool
}

enum XNewsKeychain {
    static let service = "local.resetradar.x"
    private static let account = "bearer-token"
    static func validToken(_ token:String)->Bool {
        (20...4096).contains(token.utf8.count) && token.range(of:"^[A-Za-z0-9%._~+/=\\-]+$",options:.regularExpression) != nil
    }
    static func read()->String? {
        let query:[String:Any] = [kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:account,kSecReturnData as String:true,kSecMatchLimit as String:kSecMatchLimitOne]
        var result:CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary,&result) == errSecSuccess,
              let data = result as? Data,let token = String(data:data,encoding:.utf8),validToken(token) else { return nil }
        return token
    }
    static func save(_ token:String) throws {
        guard validToken(token) else { throw NewsCheckFailure(kind:.xToken,message:"Paste only your X app’s Bearer Token, without spaces or the word Bearer.") }
        let query:[String:Any] = [kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:account]
        let status = SecItemUpdate(query as CFDictionary,[kSecValueData as String:Data(token.utf8)] as CFDictionary)
        if status == errSecItemNotFound {
            var new = query; new[kSecValueData as String] = Data(token.utf8)
            new[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(new as CFDictionary,nil) == errSecSuccess else { throw NewsCheckFailure(kind:.xToken,message:"The X token could not be saved in macOS Keychain. Try again.") }
        } else if status != errSecSuccess { throw NewsCheckFailure(kind:.xToken,message:"The X token could not be updated in macOS Keychain. Try again.") }
    }
    static func remove()->Bool {
        let status = SecItemDelete([kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:account] as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// Reservations count possible returned resources, including uncertain failures.
// This is a local usage guard; the X console controls the actual monetary limit.
enum XNewsBudget {
    static let allowedPostLimits = [100,200,500,1000,2000]
    private static let lock = NSLock()
    private static let dayKey = "xDailyUsageDay"
    private static let postKey = "xDailyPostsReserved"
    private static let userKey = "xDailyUsersReserved"
    struct Reservation { let day:String; let posts:Int; let users:Int }
    static var postLimit:Int { limit(.standard) }
    static var postsReservedToday:Int { usage(now:Date(),defaults:.standard).posts }
    static var usersReservedToday:Int { usage(now:Date(),defaults:.standard).users }
    static var nextReset:Date { reset(after:Date()) }
    private static func limit(_ defaults:UserDefaults)->Int {
        let selected = defaults.integer(forKey:"xDailyPostLimit")
        return allowedPostLimits.contains(selected) ? selected : 200
    }
    private static func day(_ now:Date)->String { String(Int(floor(now.timeIntervalSince1970/86400))) }
    private static func reset(after now:Date)->Date { Date(timeIntervalSince1970:(floor(now.timeIntervalSince1970/86400)+1)*86400) }
    private static func rotate(now:Date,defaults:UserDefaults) {
        if defaults.string(forKey:dayKey) != day(now) {
            defaults.set(day(now),forKey:dayKey); defaults.set(0,forKey:postKey); defaults.set(0,forKey:userKey)
        }
    }
    static func usage(now:Date,defaults:UserDefaults)->(posts:Int,users:Int) {
        lock.lock(); defer { lock.unlock() }; rotate(now:now,defaults:defaults)
        return (max(0,defaults.integer(forKey:postKey)),max(0,defaults.integer(forKey:userKey)))
    }
    static func availablePosts(now:Date,defaults:UserDefaults?)->Int {
        guard let defaults else { return 2000 }
        lock.lock(); defer { lock.unlock() }; rotate(now:now,defaults:defaults)
        return max(0,limit(defaults)-max(0,defaults.integer(forKey:postKey)))
    }
    static func reserve(posts:Int,users:Int,now:Date,defaults:UserDefaults?) throws -> Reservation? {
        guard let defaults else { return nil }
        lock.lock(); defer { lock.unlock() }; rotate(now:now,defaults:defaults)
        let currentPosts = max(0,defaults.integer(forKey:postKey)),currentUsers = max(0,defaults.integer(forKey:userKey))
        guard posts >= 0,users >= 0,currentPosts <= limit(defaults)-posts,currentUsers <= 12-users else {
            throw NewsCheckFailure(kind:.xBudget,message:"The app’s daily X read budget has been reached. Checks resume at midnight UTC; you can adjust the post limit in X connection settings.",retryAt:reset(after:now))
        }
        defaults.set(currentPosts+posts,forKey:postKey); defaults.set(currentUsers+users,forKey:userKey)
        return Reservation(day:day(now),posts:posts,users:users)
    }
    static func refundUnused(_ reservation:Reservation?,posts:Int = 0,users:Int = 0,defaults:UserDefaults?) {
        guard let reservation,let defaults else { return }
        lock.lock(); defer { lock.unlock() }
        guard defaults.string(forKey:dayKey) == reservation.day else { return }
        defaults.set(max(0,defaults.integer(forKey:postKey)-min(reservation.posts,max(0,posts))),forKey:postKey)
        defaults.set(max(0,defaults.integer(forKey:userKey)-min(reservation.users,max(0,users))),forKey:userKey)
    }
}

// One operation is one logical news check. Successful retrieval is reused when
// only the later Codex analysis needs a retry. Secrets never enter the disk cache.
final class XNewsOperation: @unchecked Sendable {
    typealias Transport = (URLRequest) throws -> (Data,HTTPURLResponse)
    static let accounts = ["thsottiaux","reach_vb","OpenAI","OpenAIDevs"]
    private static let normalizedAccounts = accounts.map { $0.lowercased() }
    private let stateLock = NSLock()
    private let fetchLock = NSLock()
    private var cancelled = false
    private var activeTask:SafeNetwork?
    private var snapshot:XNewsSnapshot?
    private var tokenHash:Data?
    private var userIDs:[String:String]?
    // X's integration guide and data dictionary still document tweet.fields;
    // its newer generated reference uses post.fields. Prefer explicit author
    // binding and permit a single fallback only for a known parameter error.
    private var legacyFields = true
    private var didFallbackFields = false
    private let transport:Transport?
    private let now:()->Date
    private let cacheURL:URL?
    private let budgetDefaults:UserDefaults?
    private let windowStart:Date
    private let windowEnd:Date
    private let maximumPosts = 100
    private let maximumRequests = 16
    private struct IDCache:Codable { let version:Int; let savedAt:Date; let ids:[String:String] }

    init(now:@escaping()->Date = Date.init,cacheURL:URL? = dataDir.appendingPathComponent("x-account-ids.json"),budgetDefaults:UserDefaults? = .standard,transport:Transport? = nil) {
        self.now = now; self.cacheURL = cacheURL; self.budgetDefaults = budgetDefaults; self.transport = transport
        let end = Date(timeIntervalSince1970:floor(now().timeIntervalSince1970)-10)
        windowEnd = end; windowStart = end.addingTimeInterval(-48*3600)
    }

    func cancel() {
        stateLock.lock(); cancelled = true; let task = activeTask; stateLock.unlock()
        task?.cancel()
    }

    private func checkCancellation() throws {
        stateLock.lock(); let stopped = cancelled; stateLock.unlock()
        if stopped { throw NewsCheckFailure(kind:.cancelled,message:"The X news check was cancelled.") }
    }

    func fetch(token:String) throws -> XNewsSnapshot {
        fetchLock.lock(); defer { fetchLock.unlock() }
        try checkCancellation()
        guard XNewsKeychain.validToken(token) else { throw NewsCheckFailure(kind:.xToken,message:"Connect an X app Bearer Token before checking these accounts.") }
        let hash = Data(SHA256.hash(data:Data(token.utf8)))
        if let previous = tokenHash,previous != hash { throw NewsCheckFailure(kind:.xToken,message:"The X connection changed during this check. Start a new check.") }
        tokenHash = hash
        if let snapshot { return snapshot }
        let deadline = ProcessInfo.processInfo.systemUptime+150
        var requestCount = 0
        let ids = try resolveAccounts(token:token,deadline:deadline,requestCount:&requestCount)
        var posts = [XNewsPost]()
        var byID = [String:XNewsPost]()
        var returnedCount = 0
        var textBytes = 0
        for username in Self.accounts {
            let normalized = username.lowercased()
            guard let userID = ids[normalized] else { throw unavailable("All four X accounts could not be resolved.") }
            var pageToken:String?
            var seenTokens = Set<String>()
            repeat {
                try checkCancellation()
                let remaining = maximumPosts-returnedCount
                // X requires at least five results per page. Never exceed the
                // visible total budget merely to check a final account or page.
                guard remaining >= 5 else { throw unavailable("The X check reached its 100-post limit before all four accounts were covered. The previous report is preserved.") }
                let pageSize = min(20,remaining)
                var query = [URLQueryItem(name:"start_time",value:Self.iso(windowStart)),URLQueryItem(name:"end_time",value:Self.iso(windowEnd)),URLQueryItem(name:"max_results",value:String(pageSize)),URLQueryItem(name:"exclude",value:"retweets")]
                if let pageToken { query.append(URLQueryItem(name:"pagination_token",value:pageToken)) }
                let response = try requestJSON(path:"/2/users/\(userID)/tweets",query:query,token:token,withFields:true,deadline:deadline,requestCount:&requestCount)
                let page = try decodePage(response.root,username:username,userID:userID,maximum:response.maximum)
                XNewsBudget.refundUnused(response.reservation,posts:response.maximum-page.posts.count,defaults:budgetDefaults)
                returnedCount += page.posts.count
                for post in page.posts {
                    if let prior = byID[post.id] {
                        guard prior.username == post.username,prior.text == post.text,prior.createdAt == post.createdAt else { throw invalid() }
                    } else {
                        guard textBytes <= 512_000-post.text.utf8.count else { throw unavailable("The X posts exceeded this check’s text limit. Full account coverage could not be reviewed; the previous report is preserved.") }
                        textBytes += post.text.utf8.count
                        byID[post.id] = post; posts.append(post)
                    }
                }
                pageToken = page.nextToken
                if let pageToken {
                    guard seenTokens.insert(pageToken).inserted else { throw unavailable("X repeated a pagination cursor, so account coverage could not be completed.") }
                }
            } while pageToken != nil
        }
        try checkCancellation()
        let completed = XNewsSnapshot(fetchedAt:now(),windowStart:windowStart,windowEnd:windowEnd,accounts:Self.accounts,posts:posts.sorted { $0.createdAt > $1.createdAt },coverageComplete:true)
        snapshot = completed
        return completed
    }

    private func resolveAccounts(token:String,deadline:TimeInterval,requestCount:inout Int) throws -> [String:String] {
        if let userIDs { return userIDs }
        if let cacheURL,let data = HarnessBridge.smallData(cacheURL),let cache = try? JSONDecoder().decode(IDCache.self,from:data),
           cache.version == 1,cache.savedAt <= now(),now().timeIntervalSince(cache.savedAt) < 24*3600,Self.validIDs(cache.ids) {
            userIDs = cache.ids; return cache.ids
        }
        let response = try requestJSON(path:"/2/users/by",query:[URLQueryItem(name:"usernames",value:Self.accounts.joined(separator:",")),URLQueryItem(name:"user.fields",value:"protected")],token:token,withFields:false,deadline:deadline,requestCount:&requestCount)
        let root = response.root
        try checkErrors(root)
        guard let rows = root["data"] as? [[String:Any]],rows.count == Self.accounts.count else { throw unavailable("X did not return all four monitored accounts. The previous report is preserved.") }
        var ids = [String:String]()
        for row in rows {
            guard let id = row["id"] as? String,Self.validID(id),let username = row["username"] as? String,
                  Self.normalizedAccounts.contains(username.lowercased()),ids[username.lowercased()] == nil,
                  let protected = Self.boolean(row["protected"]),!protected else { throw unavailable("A monitored X account is unavailable or protected. All four accounts must be readable to complete this check.") }
            ids[username.lowercased()] = id
        }
        guard Self.validIDs(ids) else { throw invalid() }
        userIDs = ids
        if let cacheURL { try? HarnessBridge.writePrivate(JSONEncoder().encode(IDCache(version:1,savedAt:now(),ids:ids)),to:cacheURL) }
        return ids
    }

    private func requestJSON(path:String,query:[URLQueryItem],token:String,withFields:Bool,deadline:TimeInterval,requestCount:inout Int) throws -> (root:[String:Any],reservation:XNewsBudget.Reservation?,maximum:Int) {
        while true {
            try checkCancellation()
            guard requestCount < maximumRequests else { throw unavailable("The X check reached its request limit before completing account coverage.") }
            guard ProcessInfo.processInfo.systemUptime < deadline else { throw NewsCheckFailure(kind:.timeout,message:"X took too long to return complete account coverage. The app will retry this check shortly.") }
            var components = URLComponents(); components.scheme = "https"; components.host = "api.x.com"; components.path = path
            var items = query
            var reservedPosts = 0
            if withFields {
                let available = XNewsBudget.availablePosts(now:now(),defaults:budgetDefaults)
                guard available >= 5 else { throw NewsCheckFailure(kind:.xBudget,message:"The app’s daily X post budget has been reached. Checks resume at midnight UTC; adjust the post limit in X connection settings if needed.",retryAt:Date(timeIntervalSince1970:(floor(now().timeIntervalSince1970/86400)+1)*86400)) }
                guard let index = items.firstIndex(where:{ $0.name == "max_results" }),let size = items[index].value.flatMap(Int.init) else { throw invalid() }
                reservedPosts = min(size,available); items[index].value = String(reservedPosts)
                items.append(URLQueryItem(name:legacyFields ? "tweet.fields" : "post.fields",value:legacyFields ? "author_id,created_at,entities,note_tweet,referenced_tweets,edit_history_tweet_ids,edit_controls" : "created_at,entities,note_post,edit_controls"))
            }
            components.queryItems = items
            guard let url = components.url,url.host == "api.x.com",url.scheme == "https",url.user == nil,url.password == nil else { throw invalid() }
            var request = URLRequest(url:url); request.httpMethod = "GET"
            request.timeoutInterval = min(30,max(0.1,deadline-ProcessInfo.processInfo.systemUptime))
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.setValue("Bearer "+token,forHTTPHeaderField:"Authorization")
            request.setValue("application/json",forHTTPHeaderField:"Accept")
            let reservation = try XNewsBudget.reserve(posts:reservedPosts,users:withFields ? 0 : Self.accounts.count,now:now(),defaults:budgetDefaults)
            requestCount += 1
            let data:Data; let response:HTTPURLResponse
            do {
                if let transport { (data,response) = try transport(request) }
                else { (data,response) = try network(request,deadline:deadline) }
            } catch let failure as NewsCheckFailure { throw failure }
            catch {
                try checkCancellation()
                let timedOut = (error as? URLError)?.code == .timedOut
                throw NewsCheckFailure(kind:timedOut ? .timeout : .network,message:timedOut ? "X took too long to respond. The app will retry this check shortly." : "X could not be reached. Check your internet connection; the app will retry this check shortly.")
            }
            try checkCancellation()
            guard ProcessInfo.processInfo.systemUptime <= deadline else { throw NewsCheckFailure(kind:.timeout,message:"X did not finish account coverage before this check’s time limit. The app will retry shortly.") }
            guard data.count <= SafeNetwork.maximumBytes,response.url == request.url else { throw invalid() }
            let decoded = try? JSONSerialization.jsonObject(with:data) as? [String:Any]
            if response.statusCode == 400,withFields,!didFallbackFields,let decoded,Self.isFieldCompatibilityError(decoded,legacy:legacyFields) {
                legacyFields.toggle(); didFallbackFields = true; continue
            }
            guard response.statusCode == 200 else { throw httpFailure(response,root:decoded) }
            guard let decoded else { throw invalid() }
            return (decoded,reservation,reservedPosts)
        }
    }

    private final class WaitingReply: @unchecked Sendable {
        let signal = DispatchSemaphore(value:0)
        private let lock = NSLock()
        private var value:(Data?,URLResponse?,Error?)?
        func complete(_ data:Data?,_ response:URLResponse?,_ error:Error?) {
            lock.lock(); guard value == nil else { lock.unlock(); return }
            value = (data,response,error); lock.unlock(); signal.signal()
        }
        func reply()->(Data?,URLResponse?,Error?)? { lock.lock(); defer { lock.unlock() }; return value }
    }

    private func network(_ request:URLRequest,deadline:TimeInterval) throws -> (Data,HTTPURLResponse) {
        let waiting = WaitingReply()
        let task = SafeNetwork.dataTask(with:request) { data,response,error in waiting.complete(data,response,error) }
        stateLock.lock()
        if cancelled { stateLock.unlock(); throw NewsCheckFailure(kind:.cancelled,message:"The X news check was cancelled.") }
        activeTask = task; task.resume(); stateLock.unlock()
        defer { stateLock.lock(); if activeTask === task { activeTask = nil }; stateLock.unlock() }
        let requestDeadline = min(deadline,ProcessInfo.processInfo.systemUptime+request.timeoutInterval)
        while waiting.signal.wait(timeout:.now()+0.05) == .timedOut {
            do { try checkCancellation() } catch { task.cancel(); throw error }
            if ProcessInfo.processInfo.systemUptime >= requestDeadline {
                task.cancel(); throw NewsCheckFailure(kind:.timeout,message:"X took too long to respond. The app will retry this check shortly.")
            }
        }
        try checkCancellation()
        guard let reply = waiting.reply() else { throw invalid() }
        if let error = reply.2 { throw error }
        guard let data = reply.0,let response = reply.1 as? HTTPURLResponse else { throw invalid() }
        return (data,response)
    }

    private func decodePage(_ root:[String:Any],username:String,userID:String,maximum:Int) throws -> (posts:[XNewsPost],nextToken:String?) {
        try checkErrors(root)
        guard let meta = root["meta"] as? [String:Any],let count = Self.integer(meta["result_count"]),count >= 0,count <= maximum else { throw invalid() }
        let rows:[[String:Any]]
        if let data = root["data"] { guard let decoded = data as? [[String:Any]] else { throw invalid() }; rows = decoded }
        else { rows = [] }
        guard rows.count == count else { throw invalid() }
        let nextToken:String?
        if let token = meta["next_token"] {
            guard let text = token as? String,!text.isEmpty,text.utf8.count <= 2048,text.unicodeScalars.allSatisfy({ $0.value >= 33 && $0.value <= 126 }) else { throw invalid() }
            nextToken = text
        } else { nextToken = nil }
        var result = [XNewsPost]()
        for row in rows {
            guard let authorID = row["author_id"] as? String else { throw unavailable("X omitted the author identity needed to verify these timelines. Complete account coverage could not be established.") }
            guard let id = row["id"] as? String,Self.validID(id),authorID == userID,
                  let dateText = row["created_at"] as? String,let date = Self.date(dateText),date >= windowStart,date <= windowEnd,
                  let basicText = row["text"] as? String,Self.validText(basicText) else { throw invalid() }
            if let usernameValue = row["username"] {
                guard let actual = usernameValue as? String,actual.lowercased() == username.lowercased() else { throw invalid() }
            }
            if let flag = row["truncated"] { guard Self.boolean(flag) == false else { throw unavailable("X returned truncated post content, so this check could not be verified.") } }
            // Long posts use a separate text object. Conflicting or malformed
            // aliases must not quietly turn into a shorter verified excerpt.
            var text = basicText
            var longTexts = [String]()
            for key in ["note_post","note_tweet"] where row[key] != nil {
                guard let note = row[key] as? [String:Any],let full = note["text"] as? String,Self.validText(full) else { throw invalid() }
                longTexts.append(full)
            }
            if let full = longTexts.first {
                guard longTexts.allSatisfy({ $0 == full }) else { throw invalid() }
                text = full
            } else if (basicText.hasSuffix("…") || basicText.hasSuffix("...")),basicText.count >= 275 {
                throw unavailable("X returned a possible long-post excerpt without its full text. The previous report is preserved.")
            }
            for key in ["referenced_posts","referenced_tweets"] where row[key] != nil {
                guard let references = row[key] as? [[String:Any]] else { throw invalid() }
                for reference in references {
                    guard let type = reference["type"] as? String,["retweeted","replied_to","quoted"].contains(type),
                          let referenceID = reference["id"] as? String,Self.validID(referenceID) else { throw invalid() }
                    if type == "retweeted" { throw unavailable("X included a repost despite the requested filter, so this check could not be completed.") }
                }
            }
            if basicText.hasPrefix("RT @") { throw unavailable("X returned repost content instead of the monitored account’s original text.") }
            for key in ["edit_history_post_ids","edit_history_tweet_ids"] where row[key] != nil {
                guard let history = row[key] as? [String],!history.isEmpty,history.count <= 6,history.allSatisfy(Self.validID),history.contains(id) else { throw invalid() }
            }
            // Article bodies are not obtained by this bounded post request.
            // An article-only announcement cannot count as fully read evidence.
            if let value = row["article"] {
                guard let article = value as? [String:Any] else { throw invalid() }
                if !article.isEmpty { throw unavailable("An X Article needs a separate full-content review. This check could not cover all post content.") }
            }
            result.append(XNewsPost(id:id,username:username.lowercased(),text:text,createdAt:date))
        }
        return (result,nextToken)
    }

    private func checkErrors(_ root:[String:Any]) throws {
        if let errors = root["errors"] {
            guard let list = errors as? [[String:Any]] else { throw invalid() }
            guard list.isEmpty else { throw unavailable("X returned a partial response. All four account timelines must be complete before this check can finish.") }
        }
    }
    private func httpFailure(_ response:HTTPURLResponse,root:[String:Any]?) -> NewsCheckFailure {
        switch response.statusCode {
        case 401:return .init(kind:.xToken,message:"X rejected this Bearer Token. Replace it in the X connection settings.")
        case 402,403:return .init(kind:.xAccess,message:"X API access is unavailable. Check your app access, credit balance and spending limit in the X Developer Console.")
        case 429:
            let type = (root?["type"] as? String ?? "").lowercased()
            if type.contains("usage-capped") || type.contains("credits") || type.contains("spend") {
                return .init(kind:.xAccess,message:"X API usage or credits are unavailable. Check your spending limit and credit balance in the X Developer Console.")
            }
            let current = now()
            let reset = response.value(forHTTPHeaderField:"x-rate-limit-reset").flatMap(Double.init).flatMap { seconds -> Date? in
                guard seconds.isFinite,seconds > current.timeIntervalSince1970,seconds <= current.timeIntervalSince1970+86400 else { return nil }
                return Date(timeIntervalSince1970:seconds)
            }
            return .init(kind:.xRateLimit,message:"X has temporarily limited these requests. The app will resume after the rate limit resets.",retryAt:reset ?? current.addingTimeInterval(15*60))
        case 500...599:return .init(kind:.network,message:"X is temporarily unavailable. The app will retry this check shortly.")
        case 404:return unavailable("A monitored X account could not be read. All four accounts must be available to complete this check.")
        default:return invalid()
        }
    }
    private static func isFieldCompatibilityError(_ root:[String:Any],legacy:Bool)->Bool {
        var candidates = [root]
        if let errors = root["errors"] as? [[String:Any]] { candidates.append(contentsOf:errors) }
        return candidates.contains { item in
            let text = ["title","detail","message"].compactMap { item[$0] as? String }.joined(separator:" ").prefix(4096).lowercased()
            let fields = legacy ? ["tweet.fields","note_tweet","referenced_tweets","edit_history_tweet_ids","author_id"] : ["post.fields","note_post","referenced_posts","edit_history_post_ids"]
            let field = fields.contains(where:text.contains)
            let invalid = ["invalid","unknown","not valid","not permitted","not supported","unrecognized","unsupported"].contains(where:text.contains)
            return field && invalid
        }
    }
    private static func validID(_ value:String)->Bool { value != "0" && value.range(of:"^[0-9]{1,19}$",options:.regularExpression) != nil }
    private static func validIDs(_ ids:[String:String])->Bool {
        Set(ids.keys) == Set(normalizedAccounts) && ids.values.allSatisfy(validID) && Set(ids.values).count == accounts.count
    }
    private static func boolean(_ value:Any?)->Bool? {
        guard let number = value as? NSNumber,CFGetTypeID(number) == CFBooleanGetTypeID() else { return nil }
        return number.boolValue
    }
    private static func integer(_ value:Any?)->Int? {
        guard let number = value as? NSNumber,CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        let double = number.doubleValue
        guard double.isFinite,double.rounded() == double,abs(double) <= 1_000_000 else { return nil }
        return Int(double)
    }
    private static func validText(_ value:String)->Bool {
        !value.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && value.utf8.count <= 100_000 &&
        value.unicodeScalars.allSatisfy { $0.value >= 32 || [9,10,13].contains($0.value) }
    }
    private static func date(_ value:String)->Date? {
        guard value.utf8.count <= 40 else { return nil }
        let format = ISO8601DateFormatter(); format.formatOptions = [.withInternetDateTime,.withFractionalSeconds]
        if let date = format.date(from:value) { return date }
        format.formatOptions = [.withInternetDateTime]; return format.date(from:value)
    }
    private static func iso(_ value:Date)->String { ISO8601DateFormatter().string(from:value) }
    private func invalid()->NewsCheckFailure { .init(kind:.invalidResponse,message:"X did not return complete, readable account evidence. The previous report is preserved.") }
    private func unavailable(_ message:String)->NewsCheckFailure { .init(kind:.sourceUnavailable,message:message) }
}

// These fixtures never contact X, use Keychain, or purchase credits.
func runXNewsTests() throws {
    let date = Date(timeIntervalSince1970:1_800_000_000)
    let token = "SYNTHETIC_X_TOKEN_1234567890"
    let accountIDs = Dictionary(uniqueKeysWithValues:XNewsOperation.accounts.enumerated().map { ($0.element.lowercased(),String($0.offset+100)) })
    let profile:[[String:Any]] = XNewsOperation.accounts.map { ["id":accountIDs[$0.lowercased()]!,"username":$0,"protected":false] }
    func response(_ request:URLRequest,_ body:[String:Any],status:Int = 200,headers:[String:String] = [:]) throws -> (Data,HTTPURLResponse) {
        (try JSONSerialization.data(withJSONObject:body),HTTPURLResponse(url:request.url!,statusCode:status,httpVersion:"HTTP/1.1",headerFields:headers)!)
    }
    func post(_ id:String = "900",author:String = "100",text:String = "No scheduled extra reset.") -> [String:Any] {
        ["id":id,"author_id":author,"text":text,"created_at":"2027-01-15T07:58:00Z","edit_history_post_ids":[id]]
    }
    func page(_ rows:[[String:Any]],next:String? = nil)->[String:Any] {
        var meta:[String:Any] = ["result_count":rows.count]; if let next { meta["next_token"] = next }
        return ["data":rows,"meta":meta]
    }
    func expectFailure(_ body:[String:Any],kind:NewsCheckFailure.Kind = .invalidResponse) throws {
        let operation = XNewsOperation(now:{ date },cacheURL:nil,budgetDefaults:nil,transport:{ request in
            try response(request,request.url!.path == "/2/users/by" ? ["data":profile] : body)
        })
        do { _ = try operation.fetch(token:token); throw ConnectionFailure("X fixture unexpectedly completed") }
        catch let failure as NewsCheckFailure { assert(failure.kind == kind) }
    }
    assert(XNewsKeychain.validToken(token) && !XNewsKeychain.validToken("Bearer "+token) && !XNewsKeychain.validToken(token+"\n"))
    var calls = 0
    let complete = XNewsOperation(now:{ date },cacheURL:nil,budgetDefaults:nil,transport:{ request in
        calls += 1
        assert(request.url?.host == "api.x.com" && request.url?.scheme == "https" && request.httpMethod == "GET")
        assert(request.value(forHTTPHeaderField:"Authorization") == "Bearer "+token)
        if request.url!.path == "/2/users/by" { return try response(request,["data":Array(profile.reversed())]) }
        let items = URLComponents(url:request.url!,resolvingAgainstBaseURL:false)!.queryItems!
        assert(items.contains { $0.name == "exclude" && $0.value == "retweets" })
        assert(items.contains { $0.name == "tweet.fields" && $0.value?.contains("note_tweet") == true && $0.value?.contains("author_id") == true })
        if request.url!.path == "/2/users/100/tweets" {
            var long = post(); long["note_post"] = ["text":"Full long post announcement: no extra reset has been scheduled."]
            return try response(request,page([long]))
        }
        return try response(request,page([]))
    })
    let snapshot = try complete.fetch(token:token)
    assert(snapshot.coverageComplete && snapshot.accounts.count == 4 && snapshot.posts.count == 1 && snapshot.posts[0].text.hasPrefix("Full long"))
    assert(snapshot.posts[0].sourceURL == "https://x.com/thsottiaux/status/900" && snapshot.windowEnd.timeIntervalSince(snapshot.windowStart) == 48*3600)
    _ = try complete.fetch(token:token); assert(calls == 5)
    try expectFailure(["data":[post()],"errors":[["title":"Not Found"]],"meta":["result_count":1]],kind:.sourceUnavailable)
    try expectFailure(page([post(author:"999")]))
    var missingAuthor = post(); missingAuthor.removeValue(forKey:"author_id"); try expectFailure(page([missingAuthor]),kind:.sourceUnavailable)
    try expectFailure(["data":[post()],"meta":["result_count":true]])
    var missingTime = post(); missingTime.removeValue(forKey:"created_at"); try expectFailure(page([missingTime]))
    var old = post(); old["created_at"] = "2020-01-01T00:00:00Z"; try expectFailure(page([old]))
    var truncated = post(); truncated["truncated"] = true; try expectFailure(page([truncated]),kind:.sourceUnavailable)
    var note = post(); note["note_post"] = ["text":42]; try expectFailure(page([note]))
    var repost = post(); repost["referenced_posts"] = [["type":"retweeted","id":"901"]]; try expectFailure(page([repost]),kind:.sourceUnavailable)
    try expectFailure(page([],next:"same"),kind:.sourceUnavailable)
    for badProfile in [["data":Array(profile.prefix(3))],["data":profile,"errors":[["title":"Unavailable user"]]]] {
        let missing = XNewsOperation(now:{ date },cacheURL:nil,budgetDefaults:nil,transport:{ request in try response(request,badProfile) })
        do { _ = try missing.fetch(token:token); throw ConnectionFailure("Accepted missing X account coverage") }
        catch let failure as NewsCheckFailure { assert(failure.kind == .sourceUnavailable) }
    }
    var multiCalls = 0
    let multiple = XNewsOperation(now:{ date },cacheURL:nil,budgetDefaults:nil,transport:{ request in
        if request.url!.path == "/2/users/by" { return try response(request,["data":profile]) }
        if request.url!.path == "/2/users/100/tweets" {
            multiCalls += 1
            let items = URLComponents(url:request.url!,resolvingAgainstBaseURL:false)!.queryItems!
            assert(items.contains { $0.name == "end_time" && $0.value == "2027-01-15T07:59:50Z" })
            if multiCalls == 1 { return try response(request,page([post("901")],next:"older")) }
            assert(items.contains { $0.name == "pagination_token" && $0.value == "older" })
            return try response(request,page([post("900")]))
        }
        return try response(request,page([]))
    })
    let multipleSnapshot = try multiple.fetch(token:token); assert(multipleSnapshot.posts.count == 2 && multiCalls == 2)
    var emptyCalls = 0
    let emptyCursors = XNewsOperation(now:{ date },cacheURL:nil,budgetDefaults:nil,transport:{ request in
        if request.url!.path == "/2/users/by" { return try response(request,["data":profile]) }
        emptyCalls += 1; return try response(request,page([],next:"empty\(emptyCalls)"))
    })
    do { _ = try emptyCursors.fetch(token:token); throw ConnectionFailure("Accepted unbounded empty X cursors") }
    catch let failure as NewsCheckFailure { assert(failure.kind == .sourceUnavailable && emptyCalls == 15) }
    var capCalls = 0
    let cap = XNewsOperation(now:{ date },cacheURL:nil,budgetDefaults:nil,transport:{ request in
        if request.url!.path == "/2/users/by" { return try response(request,["data":profile]) }
        capCalls += 1
        return try response(request,page((0..<20).map { post(String(1000+capCalls*20+$0)) },next:"page\(capCalls)"))
    })
    do { _ = try cap.fetch(token:token); throw ConnectionFailure("Accepted incomplete capped X coverage") }
    catch let failure as NewsCheckFailure { assert(failure.kind == .sourceUnavailable && capCalls == 5) }
    var fallbackCalls = 0
    let fallback = XNewsOperation(now:{ date },cacheURL:nil,budgetDefaults:nil,transport:{ request in
        if request.url!.path == "/2/users/by" { return try response(request,["data":profile]) }
        fallbackCalls += 1
        let items = URLComponents(url:request.url!,resolvingAgainstBaseURL:false)!.queryItems!
        if fallbackCalls == 1 { return try response(request,["title":"Invalid Request","detail":"Unknown parameter tweet.fields"],status:400) }
        assert(items.contains { $0.name == "post.fields" })
        return try response(request,page([]))
    })
    let legacySnapshot = try fallback.fetch(token:token); assert(legacySnapshot.coverageComplete && fallbackCalls == 5)
    var rejectedCalls = 0
    let incompatible = XNewsOperation(now:{ date },cacheURL:nil,budgetDefaults:nil,transport:{ request in
        if request.url!.path == "/2/users/by" { return try response(request,["data":profile]) }
        rejectedCalls += 1; return try response(request,["title":"Invalid Request","detail":"PRIVATE_SYNTHETIC: invalid start_time"],status:400)
    })
    do { _ = try incompatible.fetch(token:token); throw ConnectionFailure("Accepted invalid X query") }
    catch let failure as NewsCheckFailure { assert(failure.kind == .invalidResponse && rejectedCalls == 1 && !failure.message.contains("PRIVATE_SYNTHETIC")) }
    let rate = XNewsOperation(now:{ date },cacheURL:nil,budgetDefaults:nil,transport:{ request in
        try response(request,["title":"Too Many Requests"],status:429,headers:["x-rate-limit-reset":String(Int(date.timeIntervalSince1970+120))])
    })
    do { _ = try rate.fetch(token:token); throw ConnectionFailure("Accepted X rate limit") }
    catch let failure as NewsCheckFailure { assert(failure.kind == .xRateLimit && failure.retryAt == date.addingTimeInterval(120)) }
    let stopped = XNewsOperation(now:{ date },cacheURL:nil,budgetDefaults:nil,transport:{ _ in throw ConnectionFailure("Cancelled fixture reached transport") })
    stopped.cancel()
    do { _ = try stopped.fetch(token:token); throw ConnectionFailure("Accepted cancelled X operation") }
    catch let failure as NewsCheckFailure { assert(failure.kind == .cancelled) }
    let suite = "local.resetradar.x-test."+UUID().uuidString
    let defaults = UserDefaults(suiteName:suite)!
    defer { defaults.removePersistentDomain(forName:suite) }
    assert(XNewsBudget.usage(now:date,defaults:defaults).posts == 0)
    let reserved = try XNewsBudget.reserve(posts:20,users:4,now:date,defaults:defaults)
    XNewsBudget.refundUnused(reserved,posts:19,defaults:defaults)
    assert(XNewsBudget.usage(now:date,defaults:defaults).posts == 1 && XNewsBudget.usage(now:date,defaults:defaults).users == 4)
    _ = try XNewsBudget.reserve(posts:199,users:8,now:date,defaults:defaults)
    do { _ = try XNewsBudget.reserve(posts:5,users:0,now:date,defaults:defaults); throw ConnectionFailure("Exceeded daily X budget") }
    catch let failure as NewsCheckFailure { assert(failure.kind == .xBudget && failure.retryAt != nil) }
    do { _ = try XNewsBudget.reserve(posts:0,users:4,now:date,defaults:defaults); throw ConnectionFailure("Exceeded daily X user budget") }
    catch let failure as NewsCheckFailure { assert(failure.kind == .xBudget) }
    let tomorrow = date.addingTimeInterval(86400)
    assert(XNewsBudget.usage(now:tomorrow,defaults:defaults).posts == 0)
    _ = try XNewsBudget.reserve(posts:10,users:0,now:tomorrow,defaults:defaults)
    XNewsBudget.refundUnused(reserved,posts:20,defaults:defaults)
    assert(XNewsBudget.usage(now:tomorrow,defaults:defaults).posts == 10)
    defaults.removePersistentDomain(forName:suite)
    var failNetwork = true
    let retry = XNewsOperation(now:{ date },cacheURL:nil,budgetDefaults:defaults,transport:{ request in
        if request.url!.path == "/2/users/by" { return try response(request,["data":profile]) }
        if failNetwork { throw ConnectionFailure("PRIVATE_SYNTHETIC_NETWORK") }
        return try response(request,page([]))
    })
    do { _ = try retry.fetch(token:token); throw ConnectionFailure("Accepted failed X request") }
    catch let failure as NewsCheckFailure { assert(failure.kind == .network && !failure.message.contains("PRIVATE_SYNTHETIC")) }
    assert(XNewsBudget.usage(now:date,defaults:defaults).posts == 20 && XNewsBudget.usage(now:date,defaults:defaults).users == 4)
    failNetwork = false
    let retrySnapshot = try retry.fetch(token:token)
    assert(retrySnapshot.coverageComplete && XNewsBudget.usage(now:date,defaults:defaults).posts == 20 && XNewsBudget.usage(now:date,defaults:defaults).users == 4)
    print("PASS: X account binding; immutable 48-hour snapshot; full long-post text; partial errors; exact API host; pagination cycles and 100-post cap; schema compatibility; rate limits; cancellation; cached retrieval; no live API requests")
}
