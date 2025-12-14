# Created by Zap installer
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"

plug "zsh-users/zsh-autosuggestions"
plug "zap-zsh/supercharge"
# plug "devadathanmb/zap-robbyrussell"
plug "zap-zsh/fzf"
plug "Aloxaf/fzf-tab"
plug "Freed-Wu/fzf-tab-source"
plug "zap-zsh/vim"
plug "zap-zsh/completions"
plug "zsh-users/zsh-syntax-highlighting"


# Load and initialise completion system
autoload -Uz compinit
compinit
export PATH="$PATH:/home/dev/.local/bin"

# Pipx stuff
autoload -U bashcompinit
bashcompinit
eval "$(register-python-argcomplete pipx)"

# .zshrc
fpath+=($HOME/.zsh/pure)
# .zshrc
autoload -U promptinit; promptinit
prompt pure

alias ldocker="lazydocker"
alias lgit="lazygit"

. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh --disable-up-arrow)"
