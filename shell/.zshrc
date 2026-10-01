# Homebrew and command-line tools. Keep PATH entries unique.
typeset -U path fpath
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

export PYENV_ROOT="$HOME/.pyenv"
export NVM_DIR="$HOME/.nvm"
export BUN_INSTALL="$HOME/.bun"

for tool_dir in "$HOME/.local/bin" "$PYENV_ROOT/bin" "$BUN_INSTALL/bin" \
  /usr/local/mysql/bin "${HOMEBREW_PREFIX:-/usr/local}/opt/llvm/bin"; do
  [[ -d "$tool_dir" ]] && path=("$tool_dir" $path)
done
unset tool_dir

# Register Docker completions before Oh My Zsh initializes completion.
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)

# Prompt and Git helpers. Agnoster needs a Powerline-compatible font.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(git)
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
  prompt_context() {} # Hide the username/hostname segment.
else
  autoload -Uz compinit
  compinit
fi

# Language runtimes (only initialized when installed).
if (( $+commands[pyenv] )); then
  eval "$(pyenv init - zsh)"
fi
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"

# Optional Google Cloud SDK installed in the home directory.
for sdk_file in "$HOME/google-cloud-sdk/path.zsh.inc" "$HOME/google-cloud-sdk/completion.zsh.inc"; do
  [[ -r "$sdk_file" ]] && source "$sdk_file"
done
unset sdk_file

# Optional Miniconda; keep absent installations from causing startup errors.
for conda_root in /opt/miniconda3 "$HOME/miniconda3"; do
  if [[ -x "$conda_root/bin/conda" ]]; then
    if conda_setup="$("$conda_root/bin/conda" shell.zsh hook 2>/dev/null)"; then
      eval "$conda_setup"
    elif [[ -r "$conda_root/etc/profile.d/conda.sh" ]]; then
      source "$conda_root/etc/profile.d/conda.sh"
    fi
    break
  fi
done
unset conda_root conda_setup

# Activate a directory's venv/.venv after navigation, without overriding cd.
# Only navigate into trusted directories: activation scripts execute shell code.
autoload -Uz add-zsh-hook
_auto_virtualenv() {
  if [[ -n "$VIRTUAL_ENV" ]] && (( $+functions[deactivate] )); then
    deactivate
  fi
  if [[ -r venv/bin/activate ]]; then
    source venv/bin/activate
  elif [[ -r .venv/bin/activate ]]; then
    source .venv/bin/activate
  fi
  return 0
}
add-zsh-hook -d chpwd _auto_virtualenv
add-zsh-hook chpwd _auto_virtualenv

# Personal Git shortcuts.
alias gc='git commit -m'
alias gac='git add . && git commit -m'
alias gs='git status'

# Let GPG signing use this terminal.
if [[ -t 0 ]]; then
  export GPG_TTY="$(tty)"
fi

# Machine-specific paths, credentials, and private aliases stay outside Git.
if [[ -r "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi
