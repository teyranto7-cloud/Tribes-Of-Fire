"""Real startup in isolated user profiles: malformed preferences and corrupt saves."""
from pathlib import Path
import argparse
import os
import re
import shutil
import subprocess
import tempfile
import uuid

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--godot', default='godot')
args = parser.parse_args()
engine = shutil.which(args.godot) or args.godot
ERROR = re.compile(r'SCRIPT ERROR:|^ERROR:', re.MULTILINE)
checks = 0
user_directory = None
with tempfile.TemporaryDirectory(prefix='Tribes startup Joao ') as temporary:
    base = Path(temporary)
    project = base / 'project'
    shutil.copytree(ROOT, project, ignore=shutil.ignore_patterns(
        '.git', '.godot', '.github', 'Downloads', 'dist', 'builds', '.local', '__pycache__'))
    nonce = 'TribesStartupQA-' + uuid.uuid4().hex
    settings = project / 'project.godot'
    content = settings.read_text(encoding='utf-8').replace(
        '[application]', '[application]\nconfig/use_custom_user_dir=true\n'
        'config/custom_user_dir_name="' + nonce + '"', 1)
    settings.write_text(content, encoding='utf-8')
    (project / 'qa_locate.gd').write_text(
        'extends SceneTree\nfunc _initialize() -> void:\n'
        '\tvar file := FileAccess.open("res://qa_userdir.txt", FileAccess.WRITE)\n'
        '\tfile.store_string(OS.get_user_data_dir())\n\tfile.close()\n\tquit()\n', encoding='utf-8')
    env = os.environ.copy()
    for key, name in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
        env[key] = str(base / name)
    logs = ROOT / 'builds/verification'
    logs.mkdir(parents=True, exist_ok=True)

    def run(name, options, expected=0):
        result = subprocess.run([engine, '--headless', '--path', str(project), *options],
                                env=env, cwd=project, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True, timeout=45)
        (logs / (name + '.log')).write_text(result.stdout, encoding='utf-8')
        assert result.returncode == expected, result.stdout
        assert not ERROR.search(result.stdout), result.stdout
        return result.stdout

    try:
        run('startup-import', ['--editor', '--import'])
        run('startup-userdir', ['--script', 'res://qa_locate.gd'])
        user_directory = Path((project / 'qa_userdir.txt').read_text(encoding='utf-8'))
        assert user_directory.name == nonce
        user_directory.mkdir(parents=True, exist_ok=True)
        marker = user_directory / 'qa-owned.txt'
        marker.write_text(nonce, encoding='utf-8')
        bad_preferences = ('[ui]\nlanguage={"bad": true}\n[video]\n'
                           'quality={"bad": true}\nfps=[60]\nvsync={"bad": true}\n'
                           'fullscreen=[true]\nresolution=Vector2i(100000, 100000)\n'
                           '[input]\nsensitivity={"bad": true}\ncamera_smoothing=[true]\n'
                           '[audio]\nsound={"bad": true}\n')
        for name, extra in [('startup-corrupt-preferences', []), ('startup-safe-preferences', ['--safe'])]:
            (user_directory / 'settings.cfg').write_text(bad_preferences, encoding='utf-8')
            world = base / name
            text = run(name, ['--', '--play', f'--save-dir={world}', '--quit-after-seconds=1', *extra])
            assert 'GAME_READY role=offline' in text and 'PLAYER_JOINED' in text
            assert list(world.glob('world.*.json')) and not (world / '.writer-lock').exists()
            checks += 2
        corrupt = base / 'corrupt-world'
        corrupt.mkdir()
        for name in ['world.a.json', 'world.b.json']:
            (corrupt / name).write_text('unreadable snapshot; do not overwrite', encoding='utf-8')
        text = run('startup-corrupt-world', ['--', '--server', f'--save-dir={corrupt}', '--quit-after-seconds=1'], expected=1)
        assert 'PERSISTENCE_REFUSED' in text and 'SERVER_LISTENING' not in text
        checks += 1
        assert all((corrupt / name).read_text(encoding='utf-8') == 'unreadable snapshot; do not overwrite'
                   for name in ['world.a.json', 'world.b.json'])
        assert not (corrupt / '.writer-lock').exists()
        checks += 2
    finally:
        # This randomly named profile was created by this test, never the player's profile.
        if user_directory is not None and user_directory.name == nonce:
            marker = user_directory / 'qa-owned.txt'
            if marker.is_file() and marker.read_text(encoding='utf-8') == nonce:
                shutil.rmtree(user_directory)
print(f'STARTUP_PROCESS CHECKS={checks} FAILED=0 (real isolated startup, safe mode, corrupt-save refusal)')
