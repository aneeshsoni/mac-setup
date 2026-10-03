#!/bin/bash
# Each step reports failures without preventing unrelated setup steps.
set -uo pipefail

setup_root="$(cd -- "$(dirname -- "$0")" && pwd)"
if [[ "$(uname -s)" != Darwin ]]; then
  echo "This setup is for macOS." >&2
  exit 1
fi

failures=()
warn() {
  failures+=("$1")
  echo "WARNING: $1" >&2
}

# Stage first, preserve the original (including symlinks), then replace it.
# Backups and staging files stay outside iTerm2's watched DynamicProfiles folder.
install_file() {
  local source="$1" target="$2" backup_base="${3:-${2}_old_backup}"
  local backup="$backup_base" staged index=1
  if [[ -f "$target" ]] && cmp -s "$source" "$target"; then
    echo "Already up to date: $target"
    return 0
  fi
  if [[ -d "$target" && ! -L "$target" ]]; then
    echo "Expected a file, found a directory: $target" >&2
    return 1
  fi
  mkdir -p "$(dirname "$target")" "$(dirname "$backup_base")" || return 1
  staged=$(mktemp "$(dirname "$backup_base")/.mac-setup.XXXXXX") || return 1
  if ! cp "$source" "$staged"; then
    rm -f "$staged"
    return 1
  fi
  if [[ -e "$target" || -L "$target" ]]; then
    while [[ -e "$backup" || -L "$backup" ]]; do
      backup="${backup_base}.$index"
      index=$((index + 1))
    done
    if ! mv "$target" "$backup"; then
      rm -f "$staged"
      return 1
    fi
    echo "Backup: $backup"
  else
    backup=""
  fi
  if ! mv "$staged" "$target"; then
    [[ -z "$backup" ]] || mv "$backup" "$target"
    rm -f "$staged"
    return 1
  fi
  echo "Installed: $target"
}

if command -v brew >/dev/null 2>&1; then
  if ! brew bundle install --no-upgrade --file="$setup_root/Brewfile"; then
    warn "Some Homebrew packages failed. Continuing with fonts and settings; rerun to retry."
  fi
else
  warn "Homebrew is missing. Install it from https://brew.sh, then rerun for apps. Continuing with settings."
fi

install_file "$setup_root/shell/.zshrc" "$HOME/.zshrc" || warn "Could not install ~/.zshrc."
install_file "$setup_root/iterm2/profiles.json" \
  "$HOME/Library/Application Support/iTerm2/DynamicProfiles/public-mac-setup.json" \
  "$HOME/Library/Application Support/mac-setup/backups/iterm2-profiles.json_old_backup" \
  || warn "Could not install iTerm2 profiles."

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/mac-setup.XXXXXX") || exit 1
trap 'rm -rf "$work_dir"' EXIT

# Exact Powerline font families used by iTerm2 and VS Code, pinned and verified.
while IFS='|' read -r checksum filename url; do
  [[ -n "$checksum" ]] || continue
  target="$HOME/Library/Fonts/$filename"
  if [[ -f "$target" ]]; then
    actual=$(shasum -a 256 "$target")
    [[ "${actual%% *}" != "$checksum" ]] || { echo "Font already installed: $filename"; continue; }
  fi
  download="$work_dir/$filename"
  if ! curl --fail --location --silent --show-error --retry 2 --connect-timeout 15 --max-time 120 "$url" -o "$download"; then
    warn "Could not download $filename."
    continue
  fi
  actual=$(shasum -a 256 "$download")
  if [[ "${actual%% *}" != "$checksum" ]]; then
    warn "Checksum mismatch for $filename; leaving the installed font untouched."
    continue
  fi
  install_file "$download" "$target" \
    "$HOME/Library/Application Support/mac-setup/backups/$filename" \
    || warn "Could not install $filename."
done < "$setup_root/fonts/manifest.txt"

# Decode the export without parsing/reformatting the nested JSON-with-comments.
# macOS ships Ruby; no Python or Node installation is needed for this step.
if ruby "$setup_root/scripts/extract-vscode.rb" "$setup_root/vscode/setup.code-profile" "$work_dir"; then
  vscode_user="$HOME/Library/Application Support/Code/User"
  for file in settings.json keybindings.json; do
    install_file "$work_dir/$file" "$vscode_user/$file" || warn "Could not install VS Code $file."
  done

  code_cli=""
  if command -v code >/dev/null 2>&1; then
    code_cli=$(command -v code)
  else
    for candidate in "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" \
      "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"; do
      if [[ -x "$candidate" ]]; then code_cli="$candidate"; break; fi
    done
  fi
  if [[ -n "$code_cli" ]]; then
    while IFS= read -r extension; do
      "$code_cli" --profile Default --install-extension "$extension" \
        || warn "Could not install VS Code extension $extension."
    done < "$work_dir/extensions.txt"
  else
    warn "VS Code settings were copied, but its CLI is missing. Rerun after installing VS Code for extensions."
  fi
else
  warn "Could not extract VS Code settings (Ruby is required)."
fi

echo
echo "Setup steps finished. Open a new terminal to load the shell configuration."
echo "In iTerm2, choose a Mac Setup profile and set your preferred default."
echo "In VS Code, use the Default profile to see the installed settings and extensions."
echo "In Rectangle settings, import: $setup_root/rectangle/RectangleConfig.json"
echo "See README.md for Oh My Zsh, app permissions, and Ctrl+Arrow shortcuts."
if [[ ${#failures[@]} -gt 0 ]]; then
  printf '\nSome steps need attention; successful steps were kept:\n'
  printf '  - %s\n' "${failures[@]}"
  exit 1
fi
echo "All automatic setup steps completed."
