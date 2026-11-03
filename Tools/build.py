"""Import, test and cross-export Tribes of Fire with an installed Godot editor."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from version import file_version
from source_manifest import private_path


ROOT = Path(__file__).resolve().parents[1]
ERROR = re.compile(r"(?:SCRIPT ERROR:|Parse Error:|^ERROR:|ObjectDB instances leaked)", re.MULTILINE)


def runtime_environment() -> dict[str, str]:
    result = os.environ.copy()
    cloud_data = Path('/workspace/.cache/tribes-of-fire/data')
    if not result.get('XDG_DATA_HOME') and cloud_data.is_dir():
        result['XDG_DATA_HOME'] = str(cloud_data)
    # Fontconfig can otherwise attempt a read-only home cache in managed sessions.
    cache = Path(result.get('XDG_CACHE_HOME', str(ROOT / '.godot' / 'cache')))
    cache.mkdir(parents=True, exist_ok=True)
    result['XDG_CACHE_HOME'] = str(cache)
    return result


def run(engine: str, options: list[str], log_name: str, env: dict[str, str]) -> str:
    command = [engine, '--headless', '--path', str(ROOT), *options]
    print('+', ' '.join(command), flush=True)
    completed = subprocess.run(command, cwd=ROOT, env=env, text=True,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(completed.stdout, end='', flush=True)
    logs = ROOT / 'builds' / 'logs'
    logs.mkdir(parents=True, exist_ok=True)
    (logs / log_name).write_text(completed.stdout, encoding='utf-8')
    if completed.returncode:
        raise SystemExit(completed.returncode)
    # Godot may exit zero after a GDScript load error. Do not publish that run.
    if ERROR.search(completed.stdout):
        raise SystemExit(f'Godot reported errors; see builds/logs/{log_name}')
    return completed.stdout



def source_signature() -> str:
    digest = hashlib.sha256()
    excluded = {'.git', '.godot', '.github', 'builds', 'dist', 'Downloads', '.local', '__pycache__', 'Docs', 'Tests', 'Tools', 'LICENSES'}
    for directory, dirs, files in os.walk(ROOT):
        dirs[:] = sorted(name for name in dirs if name not in excluded)
        for name in sorted(files):
            path = Path(directory) / name
            if name.endswith('.md') or name.startswith('.') or private_path(path.relative_to(ROOT).as_posix()):
                continue
            if path.is_symlink():
                raise SystemExit(f'Unexpected application symlink: {path}')
            digest.update(path.relative_to(ROOT).as_posix().encode())
            digest.update(path.read_bytes())
    return digest.hexdigest()


def require_unchanged_source(expected: str, stage: str) -> None:
    if source_signature() != expected:
        # A partial export must never retain a receipt that permits packaging it.
        (ROOT / 'builds' / 'build-receipt.json').unlink(missing_ok=True)
        raise SystemExit(f'Application changed during {stage}; rebuild from stable sources')


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default='godot')
    parser.add_argument('--test-only', action='store_true')
    args = parser.parse_args()
    engine = shutil.which(args.godot)
    if engine is None and Path(args.godot).is_file():
        engine = str(Path(args.godot).resolve())
    if engine is None:
        raise SystemExit('Godot not found; use --godot /path/to/editor')
    env = runtime_environment()
    presets = ROOT / "export_presets.cfg"
    if presets.exists():
        content = presets.read_text(encoding="utf-8")
        updated = re.sub(r'(application/(?:file_version|product_version)=)"[^"\n]*"', lambda match: match[1] + '"' + file_version(ROOT) + '"', content)
        if updated != content: presets.write_text(updated, encoding="utf-8")
    version = subprocess.run([engine, '--version'], env=env, check=True,
                             text=True, stdout=subprocess.PIPE).stdout.strip()
    match = re.search(r'(\d+)\.(\d+)\.(\d+)', version)
    if not match or tuple(map(int, match.groups())) < (4, 3, 0):
        raise SystemExit(f'Godot 4.3+ required; found {version}')
    print('Engine:', version, flush=True)
    receipt_path = ROOT / 'builds' / 'build-receipt.json'
    if not args.test_only:
        receipt_path.unlink(missing_ok=True)
    # --import is explicitly documented to wait for imports and then quit.
    run(engine, ['--editor', '--import'], 'import.log', env)
    # Import can legitimately create UID/import metadata. Freeze the baseline
    # afterwards, before testing or exporting any target, rather than at the end.
    expected_source = source_signature()
    tests = [name for name in ('test_rules.gd', 'test_world.gd', 'test_player.gd', 'test_input.gd',
                              'test_gameplay.gd', 'test_v3.gd', 'test_gameplay_regressions.gd',
                              'test_tribes_regression.gd', 'test_ui_regressions.gd', 'test_phase2.gd', 'test_phase3.gd', 'test_frontier.gd',
                              'test_voice_regressions.gd', 'test_reliability.gd',
                              'test_startup_close.gd', 'test_playability.gd', 'test_reconstruction.gd', 'test_runner.gd')
             if (ROOT / 'Tests' / name).is_file()]
    if not tests:
        raise SystemExit('No test runner found; refusing to export an untested build')
    for name in tests:
        require_unchanged_source(expected_source, f'before {name}')
        output = run(engine, ['--script', f'res://Tests/{name}'], name + '.log', env)
        require_unchanged_source(expected_source, name)
        result = re.search(r'CHECKS=(\d+) FAILED=(\d+)', output)
        if not result or int(result[1]) <= 0 or int(result[2]) != 0:
            raise SystemExit(f'{name}: missing or failed test outcome')
    process_tests = [
        ('test_persistence_processes.py', ['--godot', engine], 'persistence-process.log'),
        ('test_startup_processes.py', ['--godot', engine], 'startup-process.log'),
        ('test_build_integrity.py', [], 'build-integrity.log'),
    ]
    for test_name, options, log_name in process_tests:
        process_test = ROOT / 'Tests' / test_name
        if not process_test.is_file():
            continue
        require_unchanged_source(expected_source, f'before {test_name}')
        completed = subprocess.run(
            [sys.executable, str(process_test), *options],
            cwd=ROOT, env=env, text=True, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT)
        print(completed.stdout, end='', flush=True)
        (ROOT / 'builds' / 'logs' / log_name).write_text(completed.stdout, encoding='utf-8')
        require_unchanged_source(expected_source, test_name)
        if completed.returncode:
            raise SystemExit(completed.returncode)
        result = re.search(r'CHECKS=(\d+) FAILED=(\d+)', completed.stdout)
        if ERROR.search(completed.stdout) or not result or int(result[1]) <= 0 or int(result[2]):
            raise SystemExit(f'{test_name} did not report passing checks')
    require_unchanged_source(expected_source, 'test completion')
    if args.test_only:
        return
    targets = [
        ('Windows Desktop', 'windows/TribesOfFire.exe'),
        ('Linux', 'linux/TribesOfFire.x86_64'),
        ('Linux Dedicated Server', 'server/TribesOfFireServer.x86_64'),
    ]
    target_hashes: dict[str, str] = {}
    for preset, relative in targets:
        require_unchanged_source(expected_source, f'before export {preset}')
        target = ROOT / 'builds' / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        run(engine, ['--export-release', preset, str(target)],
            target.parent.name + '-export.log', env)
        require_unchanged_source(expected_source, f'export {preset}')
        if not target.is_file() or target.stat().st_size < 1024:
            raise SystemExit(f'Export did not produce an executable: {target}')
        target_hashes[relative] = hashlib.sha256(target.read_bytes()).hexdigest()
    require_unchanged_source(expected_source, 'export completion')
    receipt = {'source_sha256': expected_source, 'targets': target_hashes}
    temporary = receipt_path.with_suffix('.json.tmp')
    try:
        temporary.write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
        require_unchanged_source(expected_source, 'receipt creation')
        temporary.replace(receipt_path)
    finally:
        temporary.unlink(missing_ok=True)
    print('Exports generated. Run platform smoke checks before distribution.')


if __name__ == '__main__':
    main()
