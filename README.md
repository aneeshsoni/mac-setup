# My Mac setup

My apps and settings, collected here so setting up the next Mac is a little easier: iTerm2, VS Code, Raycast, MonitorControl, Rectangle, boringNotch, and uv, plus my fonts and shell configuration.

## Run the setup

Install [Homebrew](https://brew.sh) and follow its shell setup instructions. Clone or download this repo, quit VS Code, then run this from the repo folder:

```sh
bash install.sh
```

The script installs missing apps, downloads the exact Meslo Powerline fonts (including bold and italic), and applies my shell, iTerm2 profiles, and VS Code Default profile settings, shortcuts, and extensions. Apps already in `/Applications` or `~/Applications` are kept.

Existing configs are backed up before replacement: `~/.zshrc_old_backup`, then `.1`, `.2`, and so on. VS Code backups sit beside its settings in `~/Library/Application Support/Code/User`; iTerm2 and font backups live in `~/Library/Application Support/mac-setup/backups`. Unchanged files are skipped. To revert a config, copy its backup over the installed file.

If a step fails, the rest still runs. The script lists anything needing attention at the end and returns a failure status. Fix those items and rerun; earlier backups are preserved.

## After the script finishes

1. **Check the final output.** Retry any failed downloads or installations by rerunning `bash install.sh`.
2. **Finish the shell setup.** Install [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) for the Agnoster prompt and Git plugin, keeping the `.zshrc` this script installed. If its installer replaces that file, rerun this script. Open a new terminal afterward. Fonts are already installed.
3. **Choose an iTerm2 look.** In Settings → Profiles, select a `Mac Setup` profile and make it your default: **Plum Neon**, **Plum Pastel**, **Charcoal Classic**, or **Plum Neon Solid**. The last is an opaque version of Plum Neon.
4. **Check Ctrl+Arrow.** All four profiles share shortcuts: Ctrl/Option+Left/Right moves by word, Command+Left/Right moves to the start/end of the line, and Option+Delete deletes the previous word. If Ctrl+Arrow switches desktops, disable those shortcuts under macOS System Settings → Keyboard → Keyboard Shortcuts → Mission Control.
5. **Open VS Code using its Default profile.** Settings and extensions are installed there. If you prefer a separate named profile, import [setup.code-profile](vscode/setup.code-profile) through Profiles → Import Profile instead.
6. **Import Rectangle's shortcuts.** In Rectangle settings, import [RectangleConfig.json](rectangle/RectangleConfig.json) and grant Accessibility access.
7. **Sign in and finish app setup.** Configure Raycast, grant requested macOS permissions, and sign into the apps you use.

## Making it yours

Add apps to [Brewfile](Brewfile). Optional entries for Karabiner-Elements and tmux are commented out. Tools like nvm, pyenv, and Bun load only if separately installed.

Keep private aliases, credentials, and machine-specific paths in `~/.zshrc.local`; it loads last and stays out of Git. The shell automatically activates `venv` or `.venv` when entering a directory, so use it only with trusted projects. Remove `add-zsh-hook chpwd _auto_virtualenv` for manual activation.

To change the iTerm2 profiles, edit [profiles.json](iterm2/profiles.json) and rerun the script. Edits made inside iTerm2 don't sync back here. Review future exports before committing them.
