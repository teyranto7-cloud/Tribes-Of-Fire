"""Exercise both production cycles over real ENet, reconnect and server restart.
Only scenario timing/positioning is controlled by the server test harness. Items
are collected/crafted/placed through ordinary client commands, never granted.
"""
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
LOGS = ROOT / 'builds/logs/phase3-network'
LOGS.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='tribes-phase3-net-') as temp:
    base = Path(temp)
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
        probe.bind(('127.0.0.1', 0))
        port = probe.getsockname()[1]
    for restoring in (False, True):
        processes, handles = [], []
        try:
            for role in (('server', 'actor') if restoring else ('server', 'actor', 'observer')):
                label = ('restart-' if restoring else 'cycles-') + role
                env = os.environ.copy()
                for key, suffix in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
                    env[key] = str(base / role / suffix)
                log_path = LOGS / (label + '.log')
                output = log_path.open('w')
                handles.append(output)
                options = ['--server'] if role == 'server' else ['--join=127.0.0.1']
                if restoring:
                    options.append('--phase3-restore')
                if role == 'observer':
                    options.append('--phase3-observer')
                command = ['godot', '--headless', '--path', str(ROOT), '--script', 'res://Tests/test_phase3_network.gd', '--',
                           *options, f'--port={port}', f'--save-dir={base / "world"}', '--seed=718991']
                process = subprocess.Popen(command, cwd=ROOT, env=env, stdout=output, stderr=subprocess.STDOUT)
                processes.append((label, process, log_path))
                marker = 'SERVER_LISTENING' if role == 'server' else 'PHASE3_CLIENT_READY'
                deadline = time.monotonic() + 25
                while marker not in log_path.read_text():
                    if process.poll() is not None or time.monotonic() > deadline:
                        raise RuntimeError(log_path.read_text())
                    time.sleep(.1)
            for label, process, path in processes:
                process.wait(timeout=150)
                text = path.read_text()
                print(label, 'exit=', process.returncode)
                print(text[-2400:])
                assert process.returncode == 0 and 'SCRIPT ERROR' not in text and 'ERROR:' not in text, text
                marker = 'PHASE3_NETWORK CHECKS=' if label.endswith('-server') else 'PHASE3_CLIENT_PASS'
                assert marker in text, text
        finally:
            for _, process, _ in processes:
                if process.poll() is None:
                    process.terminate()
                    process.wait(timeout=5)
            for output in handles:
                output.close()
print('PHASE3_NETWORK_PASS: two real clients, collection, two production cycles, duplicate requests, transport reconnect, paid escrow, clean server restart')
