"""Real solo -> dedicated migration with the original owner and tribe, Linux/XDG."""
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
    args = parser.parse_args()
    if os.name != 'posix':
        raise SystemExit('This process fixture requires Linux/XDG profile isolation.')
    engine = shutil.which(args.godot)
    if not engine:
        raise SystemExit('Godot not found')
    root = Path(__file__).resolve().parents[1]
    evidence = root / 'builds/verification/migration'
    evidence.mkdir(parents=True, exist_ok=True)
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
        probe.bind(('127.0.0.1', 0))
        port = probe.getsockname()[1]
    with tempfile.TemporaryDirectory(prefix='Tribes migration ') as directory:
        base = Path(directory)
        processes, logs = [], []
        def launch(stage):
            env = os.environ.copy()
            profile = 'server' if stage == 'server' else 'owner'
            for key, child in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
                env[key] = str(base / profile / child)
            log = (base / (stage + '.log')).open('w+')
            logs.append((stage, log))
            mode = {'seed': '--play', 'server': '--server', 'owner': '--join=127.0.0.1'}[stage]
            command = [engine, '--headless', '--path', str(root), '--script', 'res://Tests/test_host_migration.gd',
                       '--', mode, f'--qa-stage={stage}', f'--port={port}', f'--save-dir={base / "world"}']
            process = subprocess.Popen(command, cwd=root, env=env, stdout=log, stderr=subprocess.STDOUT)
            processes.append(process)
            return process, log
        def result(process, log, marker):
            process.wait(timeout=30)
            log.flush()
            log.seek(0)
            text = log.read()
            print(text)
            assert process.returncode == 0 and marker in text and 'ERROR:' not in text and 'HOST_MIGRATION_FAIL' not in text, text
        try:
            seed, seed_log = launch('seed')
            result(seed, seed_log, 'HOST_MIGRATION_SEED_PASS')
            server, server_log = launch('server')
            deadline = time.monotonic() + 15
            while time.monotonic() < deadline:
                server_log.flush()
                server_log.seek(0)
                if 'SERVER_LISTENING' in server_log.read(): break
                assert server.poll() is None, 'Dedicated startup failed'
                time.sleep(0.1)
            else: raise RuntimeError('Dedicated startup timed out')
            owner, owner_log = launch('owner')
            result(owner, owner_log, 'HOST_MIGRATION_OWNER_PASS')
            result(server, server_log, 'HOST_MIGRATION_SERVER_PASS')
            assert not (base / 'world/.writer-lock').exists()
            print('HOST_MIGRATION_PASS: real local save -> dedicated; original owner, 37 wood and tribe restored')
        finally:
            for process in processes:
                if process.poll() is None:
                    process.terminate()
                    process.wait(timeout=5)
            for stage, log in logs:
                log.flush()
                log.seek(0)
                (evidence / (stage + '.log')).write_text(log.read(), encoding='utf-8')
                log.close()

if __name__ == '__main__':
    main()
