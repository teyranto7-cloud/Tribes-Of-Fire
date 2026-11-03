"""Real Main scene, one dedicated server and three clients; generated audio only."""
import argparse
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default='godot')
    parser.add_argument('--keep-logs', type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    engine = shutil.which(args.godot)
    if not engine:
        raise SystemExit('Godot is missing')
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
        probe.bind(('127.0.0.1', 0))
        port = probe.getsockname()[1]
    with tempfile.TemporaryDirectory(prefix='tribes communication ') as directory:
        folder = Path(directory)
        processes, streams = [], []
        try:
            for role in ('server', 'A', 'B', 'C'):
                env = os.environ.copy()
                for key, child in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
                    env[key] = str(folder / role / child)
                log = (folder / (role + '.log')).open('w+')
                streams.append((role, log))
                options = ['--server'] if role == 'server' else ['--join=127.0.0.1']
                command = [engine, '--headless', '--path', str(root), '--script', 'res://Tests/test_communication_peer.gd', '--', *options,
                           f'--port={port}', f'--qa-role={role}', f'--save-dir={folder / "world"}']
                process = subprocess.Popen(command, cwd=root, env=env, stdout=log, stderr=subprocess.STDOUT)
                processes.append(process)
                if role == 'server':
                    deadline = time.monotonic() + 12
                    while time.monotonic() < deadline:
                        log.flush()
                        if 'SERVER_LISTENING' in (folder / 'server.log').read_text():
                            break
                        if process.poll() is not None:
                            break
                        time.sleep(0.1)
            for process in processes:
                process.wait(timeout=50)
            passed = True
            for process, (role, stream) in zip(processes, streams):
                stream.flush()
                stream.seek(0)
                text = stream.read()
                print(f'{role}: exit={process.returncode}\n{text}')
                if args.keep_logs:
                    args.keep_logs.mkdir(parents=True, exist_ok=True)
                    (args.keep_logs / f'communication-{role}.log').write_text(text)
                marker = 'COMMUNICATION_SERVER_PASS' if role == 'server' else 'COMMUNICATION_CLIENT_PASS'
                passed &= process.returncode == 0 and marker in text and 'ERROR:' not in text and 'COMMUNICATION_FAIL' not in text
            if not passed:
                raise SystemExit('Communication integration failed; inspect peer logs')
            print('COMMUNICATION_PASS: 3 clients, six text channels, spatial and remote encoded audio, privacy, block, receive playback; no microphone captured')
        finally:
            for process in processes:
                if process.poll() is None:
                    process.terminate()
                    process.wait(timeout=5)
            for _, stream in streams:
                stream.close()


if __name__ == '__main__':
    main()
