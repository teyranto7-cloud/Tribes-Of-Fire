"""Check one player's inventory across reconnect and a clean dedicated-server restart."""
import argparse
import os
from pathlib import Path
import re
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
    processes, logs, texts = [], [], []
    with tempfile.TemporaryDirectory(prefix="tribes-reconnect-") as temporary:
        folder = Path(temporary)

        def launch(label, server=False, restoring=False):
            environment = os.environ.copy()
            profile = "server" if server else "client"
            environment["XDG_DATA_HOME"] = str(folder / profile)
            environment["XDG_CACHE_HOME"] = str(folder / "cache")
            environment["XDG_CONFIG_HOME"] = str(folder / f"config-{profile}")
            log = (folder / f"{label}.log").open("w+")
            logs.append(log)
            options = ["--server"] if server else ["--join=127.0.0.1"]
            if restoring:
                options.append("--restore-check")
            command = [engine, "--headless", "--path", str(root), "--script", "res://Tests/test_reconnect.gd",
                "--", *options, f"--port={port}", f"--save-dir={folder / 'world'}"]
            process = subprocess.Popen(command, cwd=root, env=environment, stdout=log, stderr=subprocess.STDOUT)
            processes.append(process)
            return process, log

        def result(process, log, marker):
            process.wait(timeout=25)
            log.flush()
            log.seek(0)
            text = log.read()
            texts.append(text)
            print(text)
            if process.returncode != 0 or marker not in text or "ERROR:" in text:
                raise RuntimeError(f"Reconnect verification failed: {marker}")
            return text

        def ready(process, log):
            deadline = time.monotonic() + 10
            while time.monotonic() < deadline:
                log.flush()
                log.seek(0)
                if "SERVER_LISTENING" in log.read():
                    return
                if process.poll() is not None:
                    break
                time.sleep(0.1)
            raise RuntimeError("Server did not become ready")

        try:
            server, server_log = launch("server-seed", True)
            ready(server, server_log)
            first, first_log = launch("client-first")
            first_text = result(first, first_log, "RECONNECT_CLIENT_PASS")
            time.sleep(0.4)
            second, second_log = launch("client-second")
            second_text = result(second, second_log, "RECONNECT_CLIENT_PASS")
            if re.search(r"id=(\d+)", first_text).group(1) == re.search(r"id=(\d+)", second_text).group(1):
                raise RuntimeError("Test did not obtain distinct transient ENet peer IDs")
            result(server, server_log, "RECONNECT_SERVER_PASS")
            restart, restart_log = launch("server-restore", True, True)
            ready(restart, restart_log)
            third, third_log = launch("client-restored")
            result(third, third_log, "RECONNECT_CLIENT_PASS")
            result(restart, restart_log, "RECONNECT_RESTART_SERVER_PASS")
            if (folder / "world" / ".writer-lock").exists():
                raise RuntimeError("Server did not release persistence lock")
            print("RECONNECT_PASS: same inventory, different peer IDs, clean server restart, stable saved identity")
        finally:
            for process in processes:
                if process.poll() is None:
                    try:
                        process.wait(timeout=22)
                    except subprocess.TimeoutExpired:
                        process.terminate()
                        process.wait(timeout=5)
            for log in logs:
                log.flush()
                log.close()


if __name__ == "__main__":
    main()
