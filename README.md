# Antigravity CLI on Termux

Installs Google's Antigravity CLI (`agy`) on Termux and starts it. Paste this into Termux:

```
curl -fsSL https://raw.githubusercontent.com/stonxmg-lang/termux-antigravity/main/install.sh | bash
```

Then choose **Google OAuth** and sign in with your Google account. No API key is needed.

After that, run it any time with `agy`. If the command isn't found, open a new Termux session.

## Requirements

- Termux on a 64-bit (arm64) device
- About 250 MB of free space

## What the script does

- Downloads the official Android build from Google's release server and verifies its SHA-512 checksum
- Installs it to `~/.local/bin/agy` and adds that folder to your `PATH`
- Skips the download if the latest version is already installed

To install without starting it, add `--no-start`:

```
curl -fsSL https://raw.githubusercontent.com/stonxmg-lang/termux-antigravity/main/install.sh | bash -s -- --no-start
```

## Why not the official installer?

The official installer chooses the Android build only when `uname -o` reports `Android`. On Termux setups with glibc-runner it can report `GNU/Linux`, so the installer downloads a Linux build that fails with `required file not found`. This script always uses the Android build.

This is an unofficial script and isn't affiliated with Google.
