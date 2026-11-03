"""Enumerate distributable project sources without local profiles or credentials."""
from __future__ import annotations

import os
from pathlib import Path, PurePosixPath
import shutil
import subprocess

EXCLUDED_DIRECTORIES = frozenset({
    '.git', '.godot', 'builds', 'dist', 'downloads', '.local', '__pycache__',
    '.cache', '.aws', '.ssh', '.codex', '.agents', '.venv', 'venv', 'node_modules',
})
PRIVATE_NAMES = frozenset({
    'export_credentials.cfg', 'identity.cfg', 'settings.cfg', 'graphics.cfg',
    'language.cfg', 'moderation.json', 'world.a.json', 'world.b.json', 'server.json',
    'controls.cfg', 'credentials', 'credentials.json', 'credentials.cfg',
    'server.cfg', 'server-private.cfg', 'server_private.cfg', 'secrets.json',
    'secrets.cfg', '.netrc', '.npmrc', '.pypirc',
})
PRIVATE_EXTENSIONS = frozenset({'.key', '.pem', '.p12', '.pfx', '.jks', '.keystore'})
SOURCE_EXTENSIONS = frozenset({
    '.gd', '.uid', '.tscn', '.tres', '.godot', '.cfg', '.json', '.gdshader',
    '.svg', '.ico', '.png', '.wav', '.ttc', '.import', '.po', '.md', '.txt',
    '.py', '.sh', '.ps1', '.nsi', '.yml', '.yaml',
    '.glb', '.gltf', '.bin', '.obj', '.mtl', '.fbx', '.blend', '.res', '.scn',
    '.jpg', '.jpeg', '.webp', '.exr', '.hdr', '.ogg', '.mp3', '.otf', '.ttf',
    '.gdextension', '.so', '.dll', '.xml', '.csv', '.toml', '.ini',
})
PUBLIC_DOTFILES = frozenset({'.gitignore', '.gdignore', '.gitattributes', '.editorconfig'})


def private_path(relative: str | PurePosixPath) -> bool:
    parts = PurePosixPath(relative).parts
    if not parts:
        return True
    name = parts[-1].lower()
    return (name in PRIVATE_NAMES or name == '.env' or name.startswith('.env.')
            or name.endswith('.secret') or name.endswith('.secrets')
            or PurePosixPath(name).suffix in PRIVATE_EXTENSIONS
            or any(part.lower() in EXCLUDED_DIRECTORIES for part in parts[:-1]))


def source_files(root: Path) -> list[Path]:
    """Use Git's public file set when present, with a safe standalone fallback.

    Uncommitted new source files are included, ignored workstation files are not.
    Explicit private-name checks apply even to a mistakenly tracked credential.
    An extracted Source ZIP can be repackaged without requiring Git installation.
    """
    allowed: set[str] | None = None
    if (root / '.git').exists():
        if shutil.which('git') is None:
            raise SystemExit('Git checkout detected but git is unavailable; cannot honor ignored files safely')
        result = subprocess.run(
            ['git', '-C', str(root), 'ls-files', '-z', '--cached', '--others', '--exclude-standard'],
            check=True, stdout=subprocess.PIPE)
        allowed = {os.fsdecode(value) for value in result.stdout.split(b'\0') if value}
    found: list[Path] = []
    for directory, directories, names in os.walk(root):
        directories[:] = sorted(name for name in directories if name.lower() not in EXCLUDED_DIRECTORIES)
        for name in sorted(names):
            path = Path(directory) / name
            relative = path.relative_to(root).as_posix()
            if private_path(relative) or (allowed is not None and relative not in allowed):
                continue
            if name.startswith('.') and name not in PUBLIC_DOTFILES:
                continue
            if path.suffix.lower() not in SOURCE_EXTENSIONS and name not in PUBLIC_DOTFILES:
                continue
            if path.is_symlink():
                raise SystemExit('Source archive refuses unexpected symlink: ' + relative)
            found.append(path)
    return sorted(found)
