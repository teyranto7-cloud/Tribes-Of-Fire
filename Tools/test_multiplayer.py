"""Exercise the actual game scene with one dedicated server and two ENet clients."""
import argparse
import json
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
    parser.add_argument("--keep-logs", type=Path)
    parser.add_argument("--debug", action="store_true")
    args = parser.parse_args()
    engine = shutil.which(args.godot)
    if not engine:
        raise SystemExit("Godot not found")
    root = Path(__file__).resolve().parents[1]
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
        probe.bind(("127.0.0.1", 0))
        port = probe.getsockname()[1]
    processes, logs = [], []
    with tempfile.TemporaryDirectory(prefix="tribes-game-network-") as temporary:
        folder = Path(temporary)
        try:
            for index in range(3):
                logfile = folder / f"peer-{index}.log"
                log = logfile.open("w+")
                logs.append(log)
                environment = os.environ.copy()
                environment["XDG_DATA_HOME"] = str(folder / f"data-{index}")
                environment["XDG_CONFIG_HOME"] = str(folder / f"config-{index}")
                environment["XDG_CACHE_HOME"] = str(folder / "cache")
                options = ["--server", "--quit-after-seconds=15"] if index == 0 else [
                    "--join=127.0.0.1", f"--smoke-client={index}", "--quit-after-seconds=18"]
                if index == 0 and args.debug:
                    options.append("--network-debug")
                command = [engine, "--headless", "--path", str(root), "--", *options,
                    f"--port={port}", f"--save-dir={folder / ('world-' + str(index))}"]
                processes.append(subprocess.Popen(command, cwd=root, env=environment,
                    stdout=log, stderr=subprocess.STDOUT))
                if index == 0:
                    # Wait for actual application readiness, not merely a process or open port.
                    deadline = time.monotonic() + 15
                    while time.monotonic() < deadline:
                        log.flush()
                        if "SERVER_LISTENING" in logfile.read_text():
                            break
                        if processes[0].poll() is not None:
                            break
                        time.sleep(0.1)
            for process in processes:
                try:
                    process.wait(timeout=25)
                except subprocess.TimeoutExpired:
                    # Always retain diagnostics when startup or graceful shutdown is broken.
                    for peer_index, peer_log in enumerate(logs):
                        peer_log.flush()
                        peer_log.seek(0)
                        evidence = peer_log.read()
                        print(f"--- Timed-out run peer {peer_index} ---\\n{evidence}")
                        if args.keep_logs:
                            args.keep_logs.mkdir(parents=True, exist_ok=True)
                            (args.keep_logs / f"multiplayer-peer-{peer_index}.log").write_text(evidence)
                    raise
            results = []
            for index, (process, log) in enumerate(zip(processes, logs)):
                log.flush()
                log.seek(0)
                text = log.read()
                print(f"--- Game peer {index}: exit={process.returncode} ---\n{text}")
                if args.keep_logs:
                    args.keep_logs.mkdir(parents=True, exist_ok=True)
                    (args.keep_logs / f"multiplayer-peer-{index}.log").write_text(text)
                marker = "SERVER_LISTENING" if index == 0 else "MULTIPLAYER_SMOKE_OK"
                clean = "SCRIPT ERROR" not in text and "ERROR:" not in text
                shared = index == 0 or "shared_tree=true" in text
                results.append(process.returncode == 0 and marker in text and shared and clean)
            if not all(results):
                raise SystemExit("Gameplay multiplayer verification failed")
            snapshots = list((folder / "world-0").glob("world.*.json"))
            if not snapshots:
                raise SystemExit("Server exited without persisting its authoritative world")
            latest = max((json.loads(path.read_text()) for path in snapshots), key=lambda data: data["sequence"])
            state = json.loads(latest["payload"])
            wood = sum(player["inventory"]["wood"] for player in state["players"].values())
            if not state["cut"] or wood < 4 or len(state["players"]) < 2:
                raise SystemExit("Server did not persist the shared harvest and both player records")
            if (folder / "world-0" / ".writer-lock").exists():
                raise SystemExit("Server left its persistence lock behind")
            print("MULTIPLAYER_PASS: actual game scene, dedicated authority, 2 visible moving clients, shared harvest, clean logs, saved world")
        finally:
            # Each process has its own bounded graceful quit timer; allow it to save/release locks.
            for process in processes:
                if process.poll() is None:
                    try:
                        process.wait(timeout=25)
                    except subprocess.TimeoutExpired:
                        process.terminate()
                        process.wait(timeout=5)
            for log in logs:
                log.close()


if __name__ == "__main__":
    main()
