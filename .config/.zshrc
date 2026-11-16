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
# The plugins, in this order, from the first folder of the system's data that
# has each: Arch keeps them in /usr/share/zsh/plugins/<name>, NixOS in its
# profile (XDG_DATA_DIRS), some there in share/<name>. A missing one is left out.
for plugin in zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting; do
	for file in ${^${(s.:.)XDG_DATA_DIRS}}/{zsh/plugins/,}$plugin/$plugin.zsh(N) \
		/usr/share/zsh/plugins/$plugin/$plugin.zsh(N); do
		source $file
		break
	done
done
unset plugin file
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
export PATH="$HOME/.cargo/bin:$PATH"
