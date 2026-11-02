#!/data/data/com.termux/files/usr/bin/bash
#
# Installs Google's Antigravity CLI (agy) on Termux, then starts it.
# Always uses the official Android build, even on setups where `uname -o`
# reports GNU/Linux (for example with glibc-runner) and the official
# installer picks a Linux build that cannot run.
#
# Options:
#   --no-start   Install only, do not start agy
#
set -euo pipefail

BASE_URL="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app"
MANIFEST_URL="$BASE_URL/manifests/android_arm64.json"
BIN_DIR="$HOME/.local/bin"
BIN="$BIN_DIR/agy"
PATH_LINE="export PATH=\"$BIN_DIR:\$PATH\""

START=1
for arg in "$@"; do
    case "$arg" in
        --no-start) START=0 ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

fail() { echo "Error: $1" >&2; exit 1; }

case "${PREFIX:-}" in
    */com.termux/*) ;;
    *) fail "this script is for Termux only." ;;
esac

case "$(uname -m)" in
    aarch64|arm64) ;;
    *) fail "Antigravity has an Android build for arm64 only (this device is $(uname -m))." ;;
esac

missing=""
for tool in curl tar sha512sum; do
    command -v "$tool" >/dev/null 2>&1 || missing=1
done
if [ -n "$missing" ]; then
    echo "Installing required packages..."
    pkg install -y curl tar coreutils
fi

TMP="$(mktemp -d "${TMPDIR:-$PREFIX/tmp}/agy.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

echo "Checking the latest version..."
curl -fsSL "$MANIFEST_URL" -o "$TMP/manifest.json" \
    || fail "could not reach the release server. Check your internet connection."

json_value() { sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$TMP/manifest.json"; }
version="$(json_value version)"
url="$(json_value url)"
sha512="$(json_value sha512)"
[ -n "$url" ] && [ -n "$sha512" ] || fail "the release manifest could not be read."

current=""
if [ -x "$BIN" ]; then
    current="$("$BIN" --version 2>/dev/null | tail -n 1 || true)"
fi

if [ "$current" = "$version" ]; then
    echo "agy $version is already installed."
else
    echo "Downloading agy $version..."
    curl -fL --progress-bar "$url" -o "$TMP/agy.tar.gz" || fail "the download failed."

    [ "$(sha512sum "$TMP/agy.tar.gz" | cut -d' ' -f1)" = "$sha512" ] \
        || fail "checksum mismatch, nothing was installed."
    echo "Checksum verified."

    tar -xzf "$TMP/agy.tar.gz" -C "$TMP" antigravity || fail "could not extract the archive."
    mkdir -p "$BIN_DIR"
    chmod +x "$TMP/antigravity"
    mv -f "$TMP/antigravity" "$BIN"
fi

"$BIN" --version >/dev/null 2>&1 || fail "agy was installed but does not run on this device."

# Make agy available in new sessions, without adding the line twice.
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ "$rc" = "$HOME/.bashrc" ] || [ -f "$rc" ]; then
        touch "$rc"
        if ! grep -qF "$BIN_DIR" "$rc" 2>/dev/null; then
            printf '\n# Added by termux-antigravity\n%s\n' "$PATH_LINE" >> "$rc"
        fi
    fi
done

echo "Done: agy $version. Run it any time with: agy"

if [ "$START" = 1 ]; then
    # Reattach to the terminal, because `curl | bash` leaves stdin on the pipe.
    if [ -r /dev/tty ] && { : </dev/tty; } 2>/dev/null; then
        exec "$BIN" </dev/tty
    fi
    echo "No terminal available, so agy was not started."
fi
