"""Verify ENet with one authority and two independent client Godot processes."""
import argparse
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import time


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot")
    args = parser.parse_args()
    engine = shutil.which(args.godot)
    if not engine:
        raise SystemExit("Godot not found")
    root = Path(__file__).resolve().parents[1]
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
        probe.bind(("127.0.0.1", 0))
        port = probe.getsockname()[1]
    command = [engine, "--headless", "--path", str(root), "--script", "res://Tests/test_session.gd", "--"]
    processes = []
    logs = []
    with tempfile.TemporaryDirectory(prefix="tribes-network-") as directory:
        try:
            for index in range(3):
                path = Path(directory) / f"peer-{index}.log"
                log = path.open("w+")
                logs.append(log)
                options = ["--session-server"] if index == 0 else []
                environment = os.environ.copy()
                environment["XDG_DATA_HOME"] = str(Path(directory) / f"data-{index}")
                environment["XDG_CACHE_HOME"] = str(Path(directory) / "cache")
                processes.append(subprocess.Popen(command + options + [f"--port={port}"],
                    cwd=root, env=environment, stdout=log, stderr=subprocess.STDOUT))
                if index == 0:
                    time.sleep(0.4)
            for process in processes:
                process.wait(timeout=18)
            results = []
            for index, (process, log) in enumerate(zip(processes, logs)):
                log.flush()
                log.seek(0)
                text = log.read()
                print(f"--- Peer {index}: exit={process.returncode} ---\n{text}")
                marker = "SESSION_SERVER_PASS" if index == 0 else "SESSION_CLIENT_PASS"
                results.append(process.returncode == 0 and marker in text and "SCRIPT ERROR" not in text and "ERROR:" not in text)
            if not all(results):
                raise SystemExit("ENet verification failed")
            print("NETWORK_PASS: 1 authoritative server, 2 clients, malformed input/admin actions rejected")
        finally:
            for process in processes:
                if process.poll() is None:
                    process.terminate()
                    process.wait(timeout=5)
            for log in logs:
                log.close()


if __name__ == "__main__":
    main()
