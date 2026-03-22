# Created by Zap installer
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"

plug "zsh-users/zsh-autosuggestions"
plug "zap-zsh/supercharge"
plug "devadathanmb/zap-robbyrussell"
plug "zap-zsh/fzf"
plug "Aloxaf/fzf-tab"
plug "Freed-Wu/fzf-tab-source"
plug "zap-zsh/vim"
plug "zap-zsh/completions"
plug "zsh-users/zsh-syntax-highlighting"

# Path
export PATH="$PATH:/home/dev/.local/bin"