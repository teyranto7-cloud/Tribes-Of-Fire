"""Read the only release-version source: project.godot."""
from pathlib import Path
import re

def project_version(root=None):
    root=Path(root) if root is not None else Path(__file__).resolve().parents[1]
    match=re.search(r'^config/version="(\d+\.\d+\.\d+(?:-[a-z0-9.]+)?)"$',(root/'project.godot').read_text(encoding='utf-8'),re.M)
    if match is None: raise SystemExit('Missing or invalid project version')
    return match[1]

def file_version(root=None):
    return project_version(root).split('-')[0]+'.0'

if __name__=='__main__': print(project_version())
