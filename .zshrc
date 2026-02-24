# --- ENVS & PATH ---
export EDITOR=nvim
export ZSH="$HOME/.oh-my-zsh"
export PATH=$PATH:/home/pseudo/.spicetify
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt NO_NOTIFY
setopt NO_MONITOR

# --- THEME & PLUGINS ---
ZSH_THEME="robbyrussell" 

plugins=(
  git 
  sudo 
  archlinux 
  zsh-autosuggestions 
  fast-syntax-highlighting 
  copyfile 
  copybuffer
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# --- ALIASES ---
alias c='clear'
alias pf='fastfetch'
alias ls='eza -lh --group-directories-first --icons=auto'
alias ll='eza -al --group-directories-first --icons=always'
alias lt='eza -a --tree --level=2 --icons=always'
alias cd="zd"
alias ff='sudo fd -HI -a --exclude .snapshots'
alias is='fzf --preview="bat --style=numbers --color=always {}"'
alias nis='nvim $(fzf --preview="bat --color=always {}")'
alias hyprclock='~/.config/hypr/scripts/hyprclock'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Sync Aliases
dots() {
    # Default message is "sync: [date]", but allows a custom message
    local msg="${1:-sync: $(date)}"
    cd ~/dots && \
    git add . && \
    git commit -m "$msg" && \
    git push && \
    cd -
}

alias fmsync='cd ~/.config/omarchy/themes/full-moon && git add . && git commit -m "theme update: $(date)" && git push && cd -'
alias way='cd ~/waybar && git add . && git commit -m "sync: $(date)" && git push && cd -'

# --- FUNCTIONS ---
zi() { cd "$(zoxide query -i)"; }

zd() {
  if [ $# -eq 0 ]; then 
    builtin cd ~ && return
  elif [ -d "$1" ]; then 
    builtin cd "$1"
  else 
    z "$@" && printf "\U000F17A9 " && pwd
  fi
}

open() { xdg-open "$@" >/dev/null 2>&1 & }
cp2c() { [[ -z "$1" ]] && return 1; wl-copy < "$1"; }
c2f() { [[ -z "$1" ]] && return 1; wl-paste > "$1"; }

# --- WAYDROID HIDER (FIXED) ---
# Running via sh -c prevents Zsh from parsing the path as a glob attribute
hide_waydroid() {
  sh -c 'find "$HOME/.local/share/applications" -name "waydroid.*.desktop" -exec grep -L "NoDisplay=true" {} + | xargs -I {} sed -i "/\[Desktop Entry\]/a NoDisplay=true" {}' 2>/dev/null
}
hide_waydroid >/dev/null 2>&1 &!

# --- INITIALIZATION ---

# Visual Intro
if [[ $(tty) == *"pts"* ]]; then
  fortune | cowsay -r
fi

# Starship Prompt (Check [Starship.rs](https://starship.rs) for customization)
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# Zoxide (Check [Zoxide GitHub](https://github.com) for usage)
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# FZF (Check [FZF GitHub](https://github.com) for keybindings)
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
fi
