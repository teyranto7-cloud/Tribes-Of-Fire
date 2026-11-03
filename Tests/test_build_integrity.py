"""Exercise build-cohort guards and packaged documentation using isolated fixtures.

The exporter is mocked; these cases verify orchestration and file state, not
Godot compilation, rendering, native Windows behavior or executable validity.
"""

from __future__ import annotations

from contextlib import ExitStack, redirect_stdout
import io
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest
import zipfile
from unittest.mock import patch


TOOLS = Path(__file__).resolve().parents[1] / 'Tools'
sys.path.insert(0, str(TOOLS))
import build as build_tool
import package as package_tool


class BuildIntegrityTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix='tribes build integrity ')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.source = self.root / 'project.godot'
        self.source.write_text('fixture source A\n', encoding='utf-8')
        (self.root / 'Tests').mkdir()
        (self.root / 'Tests/test_rules.gd').write_text('# orchestration fixture\n')
        self.exports: list[str] = []

    @property
    def receipt(self) -> Path:
        return self.root / 'builds/build-receipt.json'

    def old_receipt(self) -> None:
        self.receipt.parent.mkdir(parents=True, exist_ok=True)
        self.receipt.write_text('{"previous_build": true}\n', encoding='utf-8')

    def invoke_build(self, mutation: str = '', test_only: bool = False) -> None:
        def exporter(_engine, options, _log_name, _environment):
            if '--import' in options:
                # Godot legitimately creates sidecars while importing. The
                # protected baseline must include these, not reject them.
                (self.root / 'Assets').mkdir(exist_ok=True)
                (self.root / 'Assets/generated.import').write_text('imported\n')
                return 'Import fixture finished\n'
            if '--script' in options:
                if mutation == 'test':
                    self.source.write_text('fixture source B\n')
                return 'RULES CHECKS=1 FAILED=%d\n' % (1 if mutation == 'failed_test' else 0)
            self.assertIn('--export-release', options)
            index = options.index('--export-release')
            preset, target = options[index + 1:index + 3]
            header = b'MZ' if preset == 'Windows Desktop' else b'\x7fELF'
            # Deliberately non-runnable fixture bytes; never distributed.
            Path(target).write_bytes(header + self.source.read_bytes() + b'x' * 1100)
            self.exports.append(preset)
            if mutation == 'first_export' and len(self.exports) == 1:
                self.source.write_text('fixture source B\n')
            if mutation == 'last_export' and len(self.exports) == 3:
                self.source.write_text('fixture source B\n')
            return 'Exporter fixture finished\n'

        arguments = ['build.py', '--godot', sys.executable]
        if test_only:
            arguments.append('--test-only')
        with ExitStack() as stack:
            stack.enter_context(patch.object(build_tool, 'ROOT', self.root))
            stack.enter_context(patch.object(build_tool, 'runtime_environment', return_value={}))
            stack.enter_context(patch.object(build_tool.shutil, 'which', return_value=sys.executable))
            stack.enter_context(patch.object(build_tool, 'run', side_effect=exporter))
            stack.enter_context(patch.object(build_tool.subprocess, 'run', return_value=
                subprocess.CompletedProcess(['fixture', '--version'], 0, '4.6.3.stable.fixture\n')))
            stack.enter_context(patch.object(sys, 'argv', arguments))
            stack.enter_context(redirect_stdout(io.StringIO()))
            build_tool.main()

    def test_stable_import_tests_and_exports_share_one_receipt(self) -> None:
        self.invoke_build()
        self.assertEqual(self.exports, ['Windows Desktop', 'Linux', 'Linux Dedicated Server'])
        receipt = json.loads(self.receipt.read_text())
        with patch.object(build_tool, 'ROOT', self.root):
            self.assertEqual(receipt['source_sha256'], build_tool.source_signature())
        self.assertEqual(len(receipt['targets']), 3)
        for relative in receipt['targets']:
            self.assertIn(b'fixture source A', (self.root / 'builds' / relative).read_bytes())

    def test_source_changed_during_rules_rejects_the_cohort(self) -> None:
        self.old_receipt()
        with self.assertRaisesRegex(SystemExit, 'Application changed during'):
            self.invoke_build('test')
        self.assertFalse(self.receipt.exists())
        self.assertEqual(self.exports, [])

    def test_source_changed_after_windows_export_stops_other_exports(self) -> None:
        self.old_receipt()
        with self.assertRaisesRegex(SystemExit, 'export Windows Desktop'):
            self.invoke_build('first_export')
        self.assertEqual(self.exports, ['Windows Desktop'])
        self.assertFalse(self.receipt.exists())
        self.assertFalse((self.root / 'builds/linux/TribesOfFire.x86_64').exists())

    def test_source_changed_at_last_export_cannot_write_receipt(self) -> None:
        with self.assertRaisesRegex(SystemExit, 'export Linux Dedicated Server'):
            self.invoke_build('last_export')
        self.assertEqual(len(self.exports), 3)
        self.assertFalse(self.receipt.exists())
        self.assertFalse(self.receipt.with_suffix('.json.tmp').exists())

    def test_test_only_does_not_export_or_create_receipt(self) -> None:
        self.invoke_build(test_only=True)
        self.assertEqual(self.exports, [])
        self.assertFalse(self.receipt.exists())

    def test_test_only_source_change_also_invalidates_old_receipt(self) -> None:
        self.old_receipt()
        with self.assertRaisesRegex(SystemExit, 'Application changed during'):
            self.invoke_build('test', test_only=True)
        self.assertFalse(self.receipt.exists())

    def test_failed_new_full_build_does_not_leave_previous_receipt(self) -> None:
        self.old_receipt()
        with self.assertRaisesRegex(SystemExit, 'missing or failed test outcome'):
            self.invoke_build('failed_test')
        self.assertEqual(self.exports, [])
        self.assertFalse(self.receipt.exists())

    def populate_package_fixture(self) -> str:
        for relative in package_tool.DOCS:
            path = self.root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('Distribution documentation fixture\n', encoding='utf-8')
        original = '\n'.join([
            '[Hashes](Downloads/%s/SHA256SUMS.txt)' % package_tool.VERSION,
            '[Communication](Docs/COMMUNICATION.md)', '[Audit](Docs/AUDIT.md)',
            '[Report](Docs/TEST_REPORT.md)', '[Manual](Tests/MANUAL.md)',
            '[Windows QA](Tools/Test-Windows.ps1)', '[Credits](CREDITS.md)',
        ])
        (self.root / 'README.md').write_text(original, encoding='utf-8')
        for name in package_tool.LICENSES:
            path = self.root / 'LICENSES' / name
            path.parent.mkdir(exist_ok=True)
            path.write_text('Attribution fixture only.\n' * 10, encoding='utf-8')
        for directory, filename, header in [('windows', 'TribesOfFire.exe', b'MZ'),
                ('linux', 'TribesOfFire.x86_64', b'\x7fELF'),
                ('server', 'TribesOfFireServer.x86_64', b'\x7fELF')]:
            path = self.root / 'builds' / directory / filename
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(header + b'packaging fixture, not executable\n' * 40)
        return original

    def test_binary_stages_include_all_linked_local_documentation(self) -> None:
        self.populate_package_fixture()
        with patch.object(package_tool, 'ROOT', self.root):
            for platform in ['Windows', 'Linux', 'Server-Linux']:
                staged = package_tool.stage(platform, self.root / ('staged-' + platform))
                for relative in package_tool.DOCS:
                    self.assertTrue((staged / relative).is_file(), (platform, relative))
                readme = (staged / 'README.md').read_text(encoding='utf-8')
                for target in re.findall(r'\]\((?!https?://)([^)]+)\)', readme):
                    self.assertTrue((staged / target).is_file(), (platform, target))

    def test_checksum_link_is_external_without_editing_source_readme(self) -> None:
        original = self.populate_package_fixture()
        with patch.object(package_tool, 'ROOT', self.root):
            staged = package_tool.stage('Windows', self.root / 'staged-Windows')
        readme = (staged / 'README.md').read_text(encoding='utf-8')
        self.assertIn('https://github.com/teyranto7-cloud/Tribes-Of-Fire/blob/main/Downloads/', readme)
        self.assertNotIn('](Downloads/', readme)
        self.assertEqual((self.root / 'README.md').read_text(encoding='utf-8'), original)

    def test_standalone_source_zip_excludes_profiles_credentials_and_builds(self) -> None:
        public = ['README.md', 'World/Terrain.gd', 'Balance/rules.json', 'Assets/model.glb',
                  'Tools/source_manifest.py', '.github/workflows/qa.yml', '.gitignore']
        private = ['export_credentials.cfg', '.env', '.env.production', 'identity.cfg',
                   'settings.cfg', 'graphics.cfg', 'private/client.key', 'private/signing.pfx',
                   '.aws/credentials', '.cache/response.json', 'Downloads/old/manifest.json',
                   'builds/trace.json', 'dist/manifest.json', '.godot/cache/test.json']
        for relative in public + private:
            file = self.root / relative
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_text('Deliberately public fixture' if relative in public else 'NONWORKING_TEST_SECRET')
        target = self.root / 'source.zip'
        package_tool.make_source_zip(self.root, target)
        with zipfile.ZipFile(target) as archive:
            names = set(archive.namelist())
            for relative in public:
                self.assertIn('TribesOfFire/' + relative, names)
            for relative in private:
                self.assertNotIn('TribesOfFire/' + relative, names)
            for member in names:
                self.assertNotIn(b'NONWORKING_TEST_SECRET', archive.read(member))

    def test_git_source_zip_respects_ignore_and_keeps_new_public_sources(self) -> None:
        subprocess.run(['git', 'init', '-q', str(self.root)], check=True)
        (self.root / '.gitignore').write_text('local-note.txt\nexport_credentials.cfg\n', encoding='utf-8')
        (self.root / 'local-note.txt').write_text('NONWORKING_TEST_SECRET')
        (self.root / 'export_credentials.cfg').write_text('NONWORKING_TEST_SECRET')
        subprocess.run(['git', '-C', str(self.root), 'add', '-f', 'export_credentials.cfg'], check=True)
        (self.root / 'new_feature.gd').write_text('extends Node\n')
        target = self.root / 'source.zip'
        package_tool.make_source_zip(self.root, target)
        with zipfile.ZipFile(target) as archive:
            self.assertIn('TribesOfFire/new_feature.gd', archive.namelist())
            self.assertNotIn('TribesOfFire/local-note.txt', archive.namelist())
            self.assertNotIn('TribesOfFire/export_credentials.cfg', archive.namelist())

    def test_runtime_signature_does_not_hash_export_credentials(self) -> None:
        with patch.object(build_tool, 'ROOT', self.root):
            before = build_tool.source_signature()
            (self.root / 'export_credentials.cfg').write_text('NONWORKING_TEST_SECRET')
            after = build_tool.source_signature()
        self.assertEqual(before, after)


if __name__ == '__main__':
    outcome = unittest.main(exit=False, verbosity=2).result
    failures = len(outcome.failures) + len(outcome.errors)
    print(f'BUILD_INTEGRITY CHECKS={outcome.testsRun} FAILED={failures}')
    raise SystemExit(0 if outcome.wasSuccessful() else 1)
