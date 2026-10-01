# Public Mac setup

This starter includes iTerm2, VS Code, Raycast, MonitorControl, Rectangle, and boringNotch in a Homebrew Brewfile, four sanitized iTerm2 profiles, and a sanitized VS Code profile. boringNotch comes from the `theboredteam/boring-notch` tap. Add other apps you want to the Brewfile. No apps have been installed by creating this folder.

## New Mac

1. Install [Homebrew](https://brew.sh), including the command-line tools and shell setup it requests.
2. Clone/download this repo and run `bash install.sh` from this folder. Homebrew installs the apps; the script copies the iTerm2 profiles. It refuses to overwrite a different existing profile file.
3. Install the fonts below.
4. Open iTerm2, choose a profile, and set your preferred default under Settings > Profiles.
5. In VS Code, open gear > Profiles, use the New Profile dropdown > Import Profile, and select `vscode/setup.code-profile`. Create/use the imported profile and allow its extensions to install.
6. Sign into apps and grant macOS permissions where requested. Configure Raycast separately; its full data export is deliberately excluded.

## iTerm2 export

`iterm2/profiles.json` contains Default, SSH Profile, OG, and tmux. Colors, font choices, keyboard mappings, and other profile settings were preserved. The four local working-directory paths were cleared; these profiles already use the default directory mode. New GUIDs prevent collisions with the original regular profiles when loaded dynamically.

The profile data contained no obvious credentials or saved SSH hosts. This export contains profiles only, not shell history, sessions, passwords, or the full app preferences database. Global iTerm2 preferences such as a global hotkey are not included.

[Dynamic profiles](https://iterm2.com/documentation-dynamic-profiles.html) load automatically from `~/Library/Application Support/iTerm2/DynamicProfiles`. The setup script copies the JSON there. To distribute future changes, edit this repo's JSON and copy the updated file to that location. UI edits do not automatically update the repo. No Python or iTerm2 scripting runtime is needed.

## Fonts and shell setup

The profiles reference these fonts at size 16:

- Default, SSH Profile, tmux: Meslo LG L DZ for Powerline (`MesloLGLDZForPowerline-Regular`).
- OG: Meslo LG M for Powerline (`MesloLGMForPowerline-Regular`).

Install the corresponding font families from the [Powerline fonts repository](https://github.com/powerline/fonts) using Font Book; they are under Meslo Dotted and Meslo. Include regular, bold, italic, and bold italic variants if you use them. The fonts are not embedded in these exports. A Meslo Nerd Font has a different name and would require changing the profile's font selection. VS Code's terminal also references Meslo LG L DZ for Powerline.

`shell/.zshrc` is a cleaned public version of the original shell configuration. The installer copies it only if `~/.zshrc` does not already exist; otherwise, it leaves that file untouched for manual comparison. It keeps Agnoster, the Oh My Zsh Git plugin, Git shortcuts, and optional runtime integrations. Project aliases, hardcoded personal paths, unused template comments, and the TeX path were removed. A `chpwd` hook preserves virtual-environment activation while keeping native `cd`, `pushd`, and `popd` behavior.

Install [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) separately to restore Agnoster and its Git plugin. Its installer may create a `.zshrc`; if so, back that up before adopting `shell/.zshrc`. The Powerline fonts above are needed for the prompt. nvm, pyenv, Bun, Google Cloud SDK, Miniconda, MySQL, and LLVM are optional and are initialized only when present. They are not installed by this starter's Brewfile. The shell configuration works without them.

Keep machine-specific paths, private aliases, and credentials in `~/.zshrc.local`, which the public configuration sources last and this repo ignores. Automatic virtual-environment activation executes `venv/bin/activate` or `.venv/bin/activate` after changing directories, so use it with trusted directories only. Remove the `add-zsh-hook chpwd _auto_virtualenv` line if you prefer manual activation.

macOS includes zsh; a profile named tmux does not install or launch tmux by itself. Shell history and private shell configuration are not included.

## Keyboard brightness

[Karabiner-Elements](https://karabiner-elements.pqrs.org/docs/pricing/) is free. It supports complex modifier-based mappings, including mapping Command plus the display brightness keys to keyboard illumination down/up. Use EventViewer to determine whether your keys produce F1/F2 or display-brightness events before choosing the input mapping. Enable only the relevant rule and disable the overlapping BetterTouchTool shortcuts when testing. This starter does not install or activate a remapping rule. Uncomment its Brewfile entry if you decide to use it.

## Public sharing

The VS Code profile retains settings, shortcuts, and 31 extension entries, with globalState removed. The iTerm2 JSON has had local home paths removed. Review future edits before committing: settings, task commands, MCP configuration, snippets, and shell files can contain credentials or private data. Keep app logins, environment secrets, SSH keys, history, and full application-data backups out of this repo.

The JSON structure and setup script syntax were checked. The setup script has not been run against this Mac or a fresh Mac, and the exported profiles have not been imported for a visual comparison.

Reference: [Homebrew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile), [VS Code profiles](https://code.visualstudio.com/docs/configure/profiles).

## Rectangle

`rectangle/RectangleConfig.json` contains the exported shortcuts and preferences. It was checked for personal paths and secrets; its values are numeric/boolean settings plus the app identifier and export version. Rectangle is included in the Brewfile. After installation, use Rectangle's settings import control to import this JSON. macOS Accessibility permission must be granted on the new machine.
