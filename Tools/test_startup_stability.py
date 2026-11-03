"""Open, save, close and resume the actual scene in 50 isolated processes."""
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
import time


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default='godot')
    parser.add_argument('--keep-logs', type=Path, default=Path('builds/reconstruction-audit/startup-50'))
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    engine = shutil.which(args.godot) or args.godot
    args.keep_logs.mkdir(parents=True, exist_ok=True)
    started = time.monotonic()
    with tempfile.TemporaryDirectory(prefix='Tribes restart QA ') as temporary:
        folder = Path(temporary)
        env = os.environ.copy()
        for key, name in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
            env[key] = str(folder / name)
        world = folder / 'Persistent world Joao'
        last_sequence = 0
        previous_players = None
        for index in range(50):
            options = ['--play', '--seed=718991'] if index == 0 else ['--continue']
            result = subprocess.run([engine, '--headless', '--path', str(root), '--',
                                     *options, '--safe', f'--save-dir={world}', '--quit-after-seconds=0.75'],
                                    cwd=root, env=env, text=True, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, timeout=35)
            (args.keep_logs / f'cycle-{index + 1:02}.log').write_text(result.stdout, encoding='utf-8')
            assert result.returncode == 0 and 'GAME_READY role=offline' in result.stdout, result.stdout
            assert 'PLAYER_JOINED' in result.stdout, result.stdout
            assert not re.search(r'^ERROR:|SCRIPT ERROR:|instances leaked', result.stdout, re.MULTILINE), result.stdout
            candidates = []
            for path in world.glob('world.[ab].json'):
                envelope = json.loads(path.read_text(encoding='utf-8'))
                digest = hashlib.sha256(f"{envelope['sequence']}:{envelope['payload']}".encode()).hexdigest()
                assert digest == envelope['digest']
                candidates.append((envelope['sequence'], json.loads(envelope['payload'])))
            sequence, data = max(candidates)
            assert sequence > last_sequence and data['version'] == 4 and data['seed'] == 718991
            assert data['world'] == {'seed': 718991, 'generator': 2, 'size': 1536}
            assert len(data['players']) == 1 and len(data['structures']) == 10
            assert previous_players is None or set(data['players']) == previous_players
            assert not (world / '.writer-lock').exists()
            last_sequence = sequence
            previous_players = set(data['players'])
            print(f'STARTUP_CYCLE_PASS cycle={index + 1} sequence={sequence}', flush=True)
    summary = {'cycles': 50, 'failed': 0, 'elapsed_seconds': time.monotonic() - started,
               'mode': 'headless source; graphical Windows and physical devices remain untested'}
    (args.keep_logs / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
    print('STARTUP_STABILITY CHECKS=50 FAILED=0')


if __name__ == '__main__':
    main()
