"""Three real ENet clients plus dedicated restart; scenario materials are fixtures."""
from pathlib import Path
import argparse
import os
import socket
import subprocess
import tempfile
import time

parser=argparse.ArgumentParser()
parser.add_argument("--soak-seconds",type=float,default=0)
args=parser.parse_args()
root = Path(__file__).resolve().parents[1]
logs = root / 'builds/logs/lifecycle-network'
logs.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='tribes-settlement-') as directory:
    base = Path(directory)
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
        probe.bind(('127.0.0.1', 0))
        port = probe.getsockname()[1]
    for restoring in (False, True):
        processes, handles = [], []
        try:
            for role in (('server', 'merchant') if restoring else ('server', 'merchant', 'buyer')):
                label = ('restart-' if restoring else 'cycle-') + role
                env = os.environ.copy()
                for key in ['XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME']:
                    env[key] = str(base / role / key)
                log_path = logs / (label + '.log')
                output = log_path.open('w'); handles.append(output)
                options = ['--server'] if role == 'server' else ['--join=127.0.0.1', '--settlement-role=' + role]
                if restoring: options.append('--settlement-restore')
                if args.soak_seconds and not restoring: options.append(f'--soak-seconds={args.soak_seconds}')
                process = subprocess.Popen(['godot', '--headless', '--path', str(root), '--script', 'res://Tests/test_lifecycle_network.gd', '--', *options, f'--port={port}', f'--save-dir={base / "world"}', '--seed=718991'], cwd=root, env=env, stdout=output, stderr=subprocess.STDOUT)
                processes.append((label, process, log_path))
                marker = 'SERVER_LISTENING' if role == 'server' else 'LIFECYCLE_CLIENT_READY'
                deadline = time.monotonic() + 30
                while marker not in log_path.read_text():
                    if process.poll() is not None or time.monotonic() > deadline: raise RuntimeError(log_path.read_text())
                    time.sleep(.1)
            for label, process, path in processes:
                process.wait(timeout=args.soak_seconds+120)
                output = path.read_text()
                print(label, 'exit=', process.returncode, flush=True)
                print(output[-7000:], flush=True)
                assert process.returncode == 0 and not any(error in output for error in ['SCRIPT ERROR', 'ERROR:', 'instances leaked']), output
                assert ('LIFECYCLE_NETWORK CHECKS=' if label.endswith('server') else 'LIFECYCLE_CLIENT_PASS') in output, output
        finally:
            for _, process, _ in processes:
                if process.poll() is None: process.terminate(); process.wait(timeout=5)
            for output in handles: output.close()
print('LIFECYCLE_NETWORK_PASS: motor removal, safe station/device demolition, stable IDs, hostile client rejection, replay, structural combat, persistent wreckage and dedicated restart')
