#!/usr/bin/env python3
"""Fail closed on unexpected release-source files and common private-data patterns."""
import re
import sys
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parent.parent
allowed = {
    '.gitignore', 'README.md', 'LICENSE', 'SECURITY.md', 'CHECKS.md',
    'Sources/main.swift', 'Resources/Info.plist', 'Resources/Connection Guide.html',
    'scripts/build.sh', 'scripts/check-source.py', 'scripts/check-package.py',
    '.github/workflows/ci.yml', '.github/dependabot.yml',
    'docs/images/hero-stack.png', 'docs/images/mascot-gallery.png',
    'docs/images/codex-news-colours.png',
}
patterns = [
    re.compile(rb'sk-[A-Za-z0-9_-]{20,}'),
    re.compile(rb'gh[pousr]_[A-Za-z0-9]{20,}'),
    re.compile(rb'github_pat_[A-Za-z0-9_]{20,}'),
    re.compile(rb'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
    re.compile(rb'/' + rb'Users/[^/\s"\']+/'),
    re.compile(rb'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'),
]
problems = []
# Build output may be ignored locally, but must never enter Git's tracked tree.
if (root / '.git').exists():
    tracked = subprocess.check_output(['git', '-C', str(root), 'ls-files', '-z']).decode().split('\0')
    problems.extend(f'{name}: unexpected tracked file' for name in tracked if name and name not in allowed)
for path in root.rglob('*'):
    relative = path.relative_to(root)
    if relative.parts[0] in {'.git', 'build'}:
        continue
    if path.is_symlink():
        problems.append(f'{relative}: symbolic link is not allowed')
        continue
    if not path.is_file():
        continue
    if relative.as_posix() not in allowed:
        problems.append(f'{relative}: unexpected source-package file')
        continue
    data = path.read_bytes()
    if any(pattern.search(data) for pattern in patterns):
        problems.append(f'{relative}: possible private data (contents suppressed)')
missing = sorted(name for name in allowed if not (root / name).is_file())
problems.extend(f'{name}: missing required file' for name in missing)
if problems:
    print('\n'.join(problems), file=sys.stderr)
    sys.exit(1)
print(f'PASS: {len(allowed)} allowlisted source files; no common secret patterns or personal home paths')
