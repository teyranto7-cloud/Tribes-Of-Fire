#!/usr/bin/env bash
# Reproduce the tested cloud toolchain without changing protected system paths.
set -euo pipefail
TRIBES_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TRIBES_CACHE=/workspace/.cache/tribes-of-fire
mkdir -p "$TRIBES_CACHE/downloads" "$TRIBES_CACHE/data" "$TRIBES_CACHE/bin"
export XDG_DATA_HOME="$TRIBES_CACHE/data"
export XDG_CACHE_HOME="$TRIBES_CACHE/cache"
mkdir -p "$XDG_CACHE_HOME"

verify_sha512() {
  python3 - "$1" "$2" <<'PY'
import hashlib, sys
from pathlib import Path
path = Path(sys.argv[1])
with path.open('rb') as stream:
    actual = hashlib.file_digest(stream, 'sha512').hexdigest()
if actual != sys.argv[2]:
    raise SystemExit('SHA512 verification failed: ' + str(path))
print('SHA512 verified:', path.name)
PY
}

TRIBES_VERSION=4.6.3
TRIBES_RELEASE=https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable
TRIBES_EDITOR_SHA=a035258da32b77f966a5376f9fa29c30a6adde826a85ba918e1605bd1fc9823eba7d85f1dd5e748956bd2ba72827c0025ffa11bb82aec91128c407a2e723c99c
TRIBES_TEMPLATES_SHA=da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68
TRIBES_GODOT="$(command -v godot || true)"
if [[ -z "$TRIBES_GODOT" ]] || [[ "$("$TRIBES_GODOT" --version)" != 4.6.3.stable.* ]]; then
  TRIBES_EDITOR_ZIP="$TRIBES_CACHE/downloads/Godot_v4.6.3-stable_linux.x86_64.zip"
  if [[ ! -f "$TRIBES_EDITOR_ZIP" ]]; then
    curl --fail --silent --show-error --location "$TRIBES_RELEASE/Godot_v4.6.3-stable_linux.x86_64.zip" -o "$TRIBES_EDITOR_ZIP.tmp"
    mv -- "$TRIBES_EDITOR_ZIP.tmp" "$TRIBES_EDITOR_ZIP"
  fi
  verify_sha512 "$TRIBES_EDITOR_ZIP" "$TRIBES_EDITOR_SHA"
  python3 - "$TRIBES_EDITOR_ZIP" "$TRIBES_CACHE/bin" <<'PY'
import sys, zipfile
from pathlib import Path
with zipfile.ZipFile(sys.argv[1]) as archive:
    name='Godot_v4.6.3-stable_linux.x86_64'
    target=Path(sys.argv[2])/name
    target.write_bytes(archive.read(name))
    target.chmod(0o755)
PY
  TRIBES_GODOT="$TRIBES_CACHE/bin/Godot_v4.6.3-stable_linux.x86_64"
fi

TRIBES_TEMPLATES="$XDG_DATA_HOME/godot/export_templates/4.6.3.stable"
if [[ ! -f "$TRIBES_TEMPLATES/linux_release.x86_64" ]] || [[ ! -f "$TRIBES_TEMPLATES/windows_release_x86_64.exe" ]]; then
  TRIBES_ARCHIVE="$TRIBES_CACHE/downloads/Godot_v4.6.3-stable_export_templates.tpz"
  if [[ ! -f "$TRIBES_ARCHIVE" ]]; then
    curl --fail --silent --show-error --location "$TRIBES_RELEASE/Godot_v4.6.3-stable_export_templates.tpz" -o "$TRIBES_ARCHIVE.tmp"
    mv -- "$TRIBES_ARCHIVE.tmp" "$TRIBES_ARCHIVE"
  fi
  verify_sha512 "$TRIBES_ARCHIVE" "$TRIBES_TEMPLATES_SHA"
  python3 - "$TRIBES_ARCHIVE" "$TRIBES_TEMPLATES" <<'PY'
from pathlib import Path
import sys, zipfile
target=Path(sys.argv[2]); target.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(sys.argv[1]) as archive:
    for name in ('linux_release.x86_64','windows_release_x86_64.exe'):
        path=target/name
        path.write_bytes(archive.read('templates/'+name)); path.chmod(0o755)
PY
fi

# Authenticated Debian indexes supply NSIS; do not use insecure repository flags.
TRIBES_APT="$TRIBES_CACHE/apt"
mkdir -p "$TRIBES_APT/lists/partial" "$TRIBES_APT/archives/partial" "$TRIBES_APT/download" "$TRIBES_APT/empty"
cat > "$TRIBES_APT/sources.list" <<'EOF'
deb [signed-by=/usr/share/keyrings/debian-archive-keyring.pgp] https://deb.debian.org/debian trixie main
EOF
cat > "$TRIBES_APT/apt.conf" <<EOF
Dir::Etc::parts "$TRIBES_APT/empty";
Dir::Etc::main "$TRIBES_APT/empty-conf";
Dir::Etc::sourcelist "$TRIBES_APT/sources.list";
Dir::Etc::sourceparts "$TRIBES_APT/empty";
Dir::Etc::preferencesparts "$TRIBES_APT/empty";
Dir::State::lists "$TRIBES_APT/lists";
Dir::Cache::archives "$TRIBES_APT/archives";
APT::Get::List-Cleanup "0";
APT::Sandbox::User "$(id -un)";
EOF
if [[ ! -x "$TRIBES_CACHE/nsis/usr/bin/makensis" ]]; then
  APT_CONFIG="$TRIBES_APT/apt.conf" /usr/bin/apt-get update
  (
    cd "$TRIBES_APT/download"
    APT_CONFIG="$TRIBES_APT/apt.conf" /usr/bin/apt-get download nsis=3.11-1 nsis-common=3.11-1
    mkdir -p "$TRIBES_CACHE/nsis"
    for TRIBES_DEB in nsis_3.11-1_amd64.deb nsis-common_3.11-1_all.deb; do
      dpkg-deb --extract "$TRIBES_DEB" "$TRIBES_CACHE/nsis"
    done
  )
fi
export NSISDIR="$TRIBES_CACHE/nsis/usr/share/nsis"
"$TRIBES_CACHE/nsis/usr/bin/makensis" -VERSION
cd -- "$TRIBES_ROOT"
python3 Tools/build.py --godot "$TRIBES_GODOT" --test-only
