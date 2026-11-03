"""Record real project files, scenes, autoloads and literal resource dependencies."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re

from build import source_signature
from source_manifest import source_files


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'builds/audit/project-inventory.json')
    args = parser.parse_args()
    files = [path for path in source_files(ROOT)
             if path.relative_to(ROOT).parts[0] not in {'Docs', 'Tests', 'Tools', '.github', 'LICENSES'}]
    entries, missing, dynamic = [], [], []
    totals: dict[str, int] = {}
    scenes = {}
    for path in files:
        relative = path.relative_to(ROOT).as_posix()
        suffix = path.suffix.lower()
        totals[suffix] = totals.get(suffix, 0) + 1
        entry = {'path': relative, 'bytes': path.stat().st_size,
                 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
        if suffix in {'.gd', '.tscn', '.tres', '.gdshader', '.godot', '.json', '.cfg'}:
            content = path.read_text(encoding='utf-8')
            entry['lines'] = len(content.splitlines())
            references = re.findall(r'(?:preload|load)\(\s*[\"\x27](res://[^\"\x27]+)', content)
            references += re.findall(r'path=\"(res://[^\"]+)\"', content)
            entry['literal_resource_references'] = sorted(set(references))
            for reference in references:
                if any(token in reference for token in ('%', '{', '*')):
                    dynamic.append({'from': relative, 'pattern': reference})
                    continue
                if not (ROOT / reference.removeprefix('res://')).exists():
                    missing.append({'from': relative, 'resource': reference})
            if suffix == '.tscn':
                scenes[relative] = re.findall(r'^\[node .+\]$', content, re.MULTILINE)
            if suffix == '.json':
                json.loads(content)
        entries.append(entry)
    project = (ROOT / 'project.godot').read_text(encoding='utf-8')
    autoload_block = re.search(r'^\[autoload\]\s*\n(.*?)(?=^\[|\Z)', project, re.MULTILINE | re.DOTALL)
    autoloads = re.findall(r'^(\w+)="\*?(res://[^\"]+)"', autoload_block[1], re.MULTILINE) if autoload_block else []
    for _, reference in autoloads:
        if not (ROOT / reference.removeprefix('res://')).is_file():
            missing.append({'from': 'project.godot autoload', 'resource': reference})
    result = {'application_source_sha256': source_signature(), 'files': entries,
              'extension_counts': totals, 'scenes': scenes, 'autoloads': dict(autoloads),
              'editor_plugins': sorted(str(p.relative_to(ROOT)) for p in ROOT.glob('addons/**/plugin.cfg')),
              'missing_literal_resources': missing,
              'dynamic_resource_patterns': dynamic,
              'scope': 'Static inventory; runtime-created nodes and dynamic paths require integration tests.'}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'PROJECT_INVENTORY files={len(entries)} scenes={len(scenes)} autoloads={len(autoloads)} missing={len(missing)} output={args.output}')
    if missing:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
