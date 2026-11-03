"""Exercise abrupt process death and explicit recovery of the single-writer lock.

Uses its own temporary folder. Never removes a real world's lock or data.
"""
import argparse
import os
from pathlib import Path
import queue
import shutil
import subprocess
import tempfile
import threading
import time


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    engine = shutil.which(args.godot) or args.godot
    command = [engine, "--headless", "--path", str(root), "--script", "res://Tests/test_rules.gd", "--"]
    with tempfile.TemporaryDirectory(prefix="tribes-lock-crash-") as temporary:
        base = Path(temporary)
        environment = os.environ.copy()
        for name, directory in [("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"), ("XDG_CONFIG_HOME", "config")]:
            path = base / directory
            path.mkdir()
            environment[name] = str(path)
        folder = base / "world"
        writer = subprocess.Popen(command + [f"--lock-hold={folder}"], env=environment,
                                  stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        lines = queue.Queue()

        def read_output():
            # Windows select() only supports sockets, not subprocess pipe handles.
            for line in iter(writer.stdout.readline, b''):
                lines.put(line)

        reader = threading.Thread(target=read_output, daemon=True)
        reader.start()
        try:
            output = bytearray()
            deadline = time.monotonic() + 10
            while b"LOCK_READY" not in output and time.monotonic() < deadline:
                try:
                    output.extend(lines.get(timeout=0.2))
                except queue.Empty:
                    if writer.poll() is not None:
                        break
            assert b"LOCK_READY" in output, output.decode(errors="replace")
            writer.kill()  # SIGKILL on POSIX, TerminateProcess on Windows; own child only.
            assert writer.wait(timeout=5) != 0
            assert (folder / ".writer-lock").is_dir(), "Abrupt death must not silently discard ownership evidence"
            subprocess.run(command + [f"--lock-probe={folder}"], env=environment, check=True,
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=10)
            # Recovery is explicit, after the only writer has demonstrably stopped.
            shutil.rmtree(folder / ".writer-lock")
            subprocess.run(command + [f"--lock-acquire-release={folder}"], env=environment, check=True,
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=10)
            assert not (folder / ".writer-lock").exists()
        finally:
            if writer.poll() is None:
                writer.kill()
                writer.wait(timeout=5)
            reader.join(timeout=2)
            writer.stdout.close()
    print("PERSISTENCE_PROCESS CHECKS=4 FAILED=0 (forced termination, refusal, explicit recovery, release)")


if __name__ == "__main__":
    main()
