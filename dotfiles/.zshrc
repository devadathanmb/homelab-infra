# Zap plugins are loaded only when Zap is installed.
# This keeps a fresh shell usable before dotfiles/bootstrap finishes.
if [[ -r "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ]]; then
  source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"

  plug "zsh-users/zsh-autosuggestions"
  plug "zap-zsh/supercharge"
  plug "zap-zsh/zap-prompt"
  plug "zap-zsh/fzf"
  plug "Aloxaf/fzf-tab"
  plug "Freed-Wu/fzf-tab-source"
  plug "zap-zsh/vim"
  plug "zap-zsh/completions"
  plug "zsh-users/zsh-syntax-highlighting"
fi

# Add user-local binaries without hard-coding the username or duplicating PATH entries.
if [[ -d "$HOME/.local/bin" && ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$PATH:$HOME/.local/bin"
fi

# Load per-user environment if a package manager installed one.
if [[ -r "$HOME/.local/bin/env" ]]; then
  source "$HOME/.local/bin/env"
fi
