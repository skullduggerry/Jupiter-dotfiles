PROMPT='%F{Cyan}%~%f>'
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=5000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
bindkey -v
zstyle :compinstall filename "$HOME/.zshrc"
autoload -Uz compinit && compinit
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
export PATH="$HOME/.cargo/bin:$PATH"
