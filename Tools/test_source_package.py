"""Verify an extracted Source ZIP can import and play without checkout caches."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import zipfile
from version import project_version


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive', type=Path, default=root / 'dist' / f'TribesOfFire-{project_version()}-Source.zip')
    parser.add_argument('--godot', default='godot')
    parser.add_argument('--keep-logs', type=Path, default=root / 'builds/reconstruction-audit/source-package')
    args = parser.parse_args()
    engine = shutil.which(args.godot) or args.godot
    args.keep_logs.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='Tribes extracted source ') as temporary:
        folder = Path(temporary)
        with zipfile.ZipFile(args.archive) as archive:
            assert archive.testzip() is None
            for member in archive.namelist():
                assert member.startswith('TribesOfFire/') and '..' not in Path(member).parts
            archive.extractall(folder)
        project = folder / 'TribesOfFire'
        assert (project / 'project.godot').is_file() and not (project / '.godot').exists()
        env = os.environ.copy()
        for variable, suffix in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
            env[variable] = str(folder / suffix)
        for name, options in [('import', ['--editor', '--import']),
                              ('play', ['--', '--play', '--safe', '--seed=71991', f'--save-dir={folder / "world"}', '--quit-after-seconds=2'])]:
            result = subprocess.run([engine, '--headless', '--path', str(project), *options],
                                    cwd=folder, env=env, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, text=True, timeout=60)
            (args.keep_logs / (name + '.log')).write_text(result.stdout, encoding='utf-8')
            assert result.returncode == 0 and not re.search(r'^ERROR:|SCRIPT ERROR:|instances leaked', result.stdout, re.MULTILINE), result.stdout
            if name == 'play': assert 'GAME_READY role=offline' in result.stdout and 'PLAYER_JOINED' in result.stdout
        saved = []
        for path in (folder / 'world').glob('world.[ab].json'):
            envelope = json.loads(path.read_text())
            assert hashlib.sha256(f"{envelope['sequence']}:{envelope['payload']}".encode()).hexdigest() == envelope['digest']
            saved.append((envelope['sequence'], json.loads(envelope['payload'])))
        _, data = max(saved)
        assert data['version'] == 4 and data['seed'] == 71991 and data['world']['size'] == 1536
        assert len(data['players']) == 1 and len(data['fishing']) == 12 and len(data['structures']) == 10
        assert not (folder / 'world' / '.writer-lock').exists()
    print('SOURCE_PACKAGE CHECKS=2 FAILED=0 (fresh import, actual play/save from extracted source)')


if __name__ == '__main__':
    main()
