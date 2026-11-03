"""Run exported Linux binaries without the editor, including a server restart."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import socket
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
ERROR = re.compile(r'(?:SCRIPT ERROR:|Parse Error:|^ERROR:)', re.MULTILINE)


def newest(folder: Path) -> tuple[int, dict]:
    candidates = []
    for path in folder.glob('world.[ab].json'):
        envelope = json.loads(path.read_text(encoding='utf-8'))
        sequence, payload = envelope['sequence'], envelope['payload']
        expected = hashlib.sha256(f'{sequence}:{payload}'.encode()).hexdigest()
        if envelope['digest'] != expected:
            raise AssertionError(f'Export wrote a snapshot with an invalid digest: {path.name}')
        candidates.append((sequence, json.loads(payload)))
    if not candidates:
        raise AssertionError('Export did not save a world')
    return max(candidates, key=lambda candidate: candidate[0])


def free_udp_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
        probe.bind(('127.0.0.1', 0))
        return probe.getsockname()[1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--linux', type=Path, default=ROOT / 'builds/linux/TribesOfFire.x86_64')
    parser.add_argument('--server', type=Path, default=ROOT / 'builds/server/TribesOfFireServer.x86_64')
    parser.add_argument('--keep-logs', type=Path, default=ROOT / 'builds/logs')
    parser.add_argument('--timeout', type=float, default=30)
    args = parser.parse_args()
    for executable in (args.linux, args.server):
        if not executable.is_file() or not os.access(executable, os.X_OK):
            raise SystemExit(f'Export missing or not executable: {executable}')
        with executable.open('rb') as file:
            if file.read(4) != b'\x7fELF':
                raise SystemExit(f'Invalid Linux executable header: {executable}')
    args.keep_logs.mkdir(parents=True, exist_ok=True)
    checks = 0
    with tempfile.TemporaryDirectory(prefix='tribes-export-smoke-') as temporary:
        base = Path(temporary)
        world = base / 'world'

        def run(name: str, executable: Path, options: list[str]) -> str:
            environment = os.environ.copy()
            for variable, name_suffix in [('XDG_DATA_HOME', 'data'),
                                          ('XDG_CONFIG_HOME', 'config'),
                                          ('XDG_CACHE_HOME', 'cache')]:
                directory = base / name_suffix
                directory.mkdir(exist_ok=True)
                environment[variable] = str(directory)
            completed = subprocess.run(
                [str(executable.resolve()), '--headless', '--', *options,
                 f'--save-dir={world}'], cwd=base, env=environment, text=True,
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=args.timeout)
            (args.keep_logs / f'export-{name}.log').write_text(completed.stdout, encoding='utf-8')
            print(f'{name}: exit={completed.returncode}\n{completed.stdout}', flush=True)
            if completed.returncode:
                raise SystemExit(completed.returncode)
            if ERROR.search(completed.stdout):
                raise SystemExit(f'Runtime errors in exported {name}')
            if (world / '.writer-lock').exists():
                raise SystemExit(f'Exported {name} left the persistence lock behind')
            return completed.stdout

        output = run('linux-play', args.linux, ['--play', '--quit-after-seconds=3'])
        assert 'GAME_READY role=offline' in output and 'PLAYER_JOINED' in output
        checks += 1
        first_sequence, first = newest(world)
        assert first['players'] and first['phase'] > 451
        assert all(player['hp'] == 100 for player in first['players'].values())
        checks += 1
        assert not (world / '.writer-lock').exists()
        checks += 1

        port = free_udp_port()
        output = run('dedicated', args.server,
                     ['--server', f'--port={port}', '--quit-after-seconds=2'])
        assert f'SERVER_LISTENING port={port}' in output and 'dedicated=true' in output
        checks += 1
        second_sequence, second = newest(world)
        assert second_sequence > first_sequence and second['phase'] > first['phase'] + 1
        assert second['players'] == first['players']
        checks += 1

        port = free_udp_port()
        output = run('dedicated-restart', args.server,
                     ['--server', f'--port={port}', '--quit-after-seconds=2'])
        assert f'SERVER_LISTENING port={port}' in output
        third_sequence, third = newest(world)
        assert third_sequence > second_sequence and third['phase'] > second['phase'] + 1
        assert third['players'] == first['players']
        checks += 1
    print(f'EXPORT CHECKS={checks} FAILED=0 (Linux client, dedicated server, restart, snapshots, released locks)')


if __name__ == '__main__':
    main()
