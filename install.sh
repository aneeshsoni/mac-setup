#!/bin/bash
set -euo pipefail

setup_root="$(cd -- "$(dirname -- "$0")" && pwd)"
if [[ "$(uname -s)" != Darwin ]]; then
  echo "This setup is for macOS." >&2
  exit 1
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "Install Homebrew from https://brew.sh and follow its shell setup instructions, then rerun this script." >&2
  exit 1
fi

brew bundle --file="$setup_root/Brewfile"

if [[ -e "$HOME/.zshrc" || -L "$HOME/.zshrc" ]]; then
  echo "Existing ~/.zshrc left unchanged. Compare it with $setup_root/shell/.zshrc to adopt the public version."
else
  cp "$setup_root/shell/.zshrc" "$HOME/.zshrc"
  echo "Installed ~/.zshrc. See README.md for optional shell dependencies."
fi

profiles_dir="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
profile_target="$profiles_dir/public-mac-setup.json"
mkdir -p "$profiles_dir"
if [[ -e "$profile_target" || -L "$profile_target" ]]; then
  if cmp -s "$setup_root/iterm2/profiles.json" "$profile_target"; then
    echo "iTerm2 profiles already match."
  else
    echo "Existing $profile_target differs; leaving it unchanged. Back it up and replace it manually to update." >&2
    exit 1
  fi
else
  cp "$setup_root/iterm2/profiles.json" "$profile_target"
fi

echo "iTerm2 profiles are installed. Open iTerm2 and select a profile; set your preferred default in Settings."
echo "In VS Code: gear > Profiles > New Profile dropdown > Import Profile, then select:"
echo "$setup_root/vscode/setup.code-profile"
echo "In Rectangle settings, import $setup_root/rectangle/RectangleConfig.json."
echo "See README.md for the required fonts and remaining setup."
