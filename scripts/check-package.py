#!/usr/bin/env python3
"""Check the generated app archive without launching its interactive UI."""
import hashlib
import plistlib
import stat
import subprocess
import tempfile
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parent.parent
archive_path = root / 'build/Reset Radar.zip'
app = 'Reset Radar.app'
expected = {
    f'{app}/Contents/Info.plist',
    f'{app}/Contents/MacOS/ResetRadar',
    f'{app}/Contents/Resources/Connection Guide.html',
    f'{app}/Contents/Resources/LICENSE.txt',
    f'{app}/Contents/_CodeSignature/CodeResources',
}


def check(condition, message):
    if not condition:
        raise SystemExit(message)


with zipfile.ZipFile(archive_path) as archive:
    entries = archive.infolist()
    names = [entry.filename for entry in entries]
    check(len(names) == len(set(names)), 'Duplicate archive entries')
    check(sum(entry.file_size for entry in entries) <= 64 * 1024 * 1024,
          'Archive exceeds the review size budget')
    for entry in entries:
        path = Path(entry.filename)
        check(not path.is_absolute() and '..' not in path.parts and
              path.parts[0] == app and not stat.S_ISLNK(entry.external_attr >> 16),
              'Unsafe archive path or symbolic link')
    check({entry.filename for entry in entries if not entry.is_dir()} == expected,
          'Archive does not match the approved app file manifest')
    check(archive.read(f'{app}/Contents/Resources/LICENSE.txt') == (root / 'LICENSE').read_bytes(),
          'Bundled license differs from the repository license')
    check(archive.read(f'{app}/Contents/Resources/Connection Guide.html') ==
          (root / 'Resources/Connection Guide.html').read_bytes(), 'Bundled guide differs')
    info = plistlib.loads(archive.read(f'{app}/Contents/Info.plist'))
    check(info == plistlib.loads((root / 'Resources/Info.plist').read_bytes()), 'Bundle metadata differs')
    check(info['LSMinimumSystemVersion'] == '13.0', 'Unexpected minimum macOS version')

checksum = hashlib.sha256(archive_path.read_bytes()).hexdigest()
check((root / 'build/SHA256.txt').read_text().strip() == checksum + '  Reset Radar.zip',
      'Checksum mismatch or machine-specific checksum path')
with tempfile.TemporaryDirectory(prefix='reset-radar-package-') as temporary:
    subprocess.run(['ditto', '-x', '-k', str(archive_path), temporary], check=True)
    bundle = Path(temporary) / app
    subprocess.run(['codesign', '--verify', '--deep', '--strict', str(bundle)], check=True)
    binary = bundle / 'Contents/MacOS/ResetRadar'
    architectures = subprocess.check_output(['lipo', '-archs', str(binary)], text=True).split()
    check(set(architectures) == {'arm64', 'x86_64'}, 'Universal architectures missing')
    check(binary.stat().st_mode & 0o111, 'App binary is not executable after extraction')
print('PASS: archive manifest, bundled license/guide, metadata, checksum, signature and universal architectures')
