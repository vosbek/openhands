# .bashrc for Universal Development Environment

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History configuration
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend
shopt -s checkwinsize

# Make less more friendly for non-text input files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Set variable identifying the chroot you work in
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Colored prompt
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# Xterm title
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Common aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Development aliases
alias python='python3'
alias pip='python3 -m pip'
alias jl='jupyter lab'
alias jn='jupyter notebook'
alias gc='git commit'
alias gs='git status'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias mvn='mvn -T 1C'

# Docker/Podman aliases
alias docker='podman'
alias dc='podman-compose'
alias dps='podman ps'
alias di='podman images'

# Utility functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Environment-specific configurations
export EDITOR=vim
export BROWSER=/usr/bin/firefox
export TERM=xterm-256color

# Development paths
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# Java configuration
if [ -n "$JAVA_HOME" ]; then
    export PATH="$JAVA_HOME/bin:$PATH"
fi

# Maven configuration
if [ -n "$MAVEN_HOME" ]; then
    export PATH="$MAVEN_HOME/bin:$PATH"
fi

# Node.js configuration
export NPM_CONFIG_PREFIX="$HOME/.local"

# Python configuration
export PYTHONPATH="$HOME/.local/lib/python3.10/site-packages:$PYTHONPATH"
export PIP_USER=yes

# AWS CLI configuration
if [ -f "$HOME/.aws/config" ]; then
    export AWS_CONFIG_FILE="$HOME/.aws/config"
fi

# Git configuration from environment variables
if [ -n "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi

if [ -n "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi

# Proxy configuration
if [ -n "$HTTP_PROXY" ]; then
    export http_proxy="$HTTP_PROXY"
    export HTTP_PROXY="$HTTP_PROXY"
fi

if [ -n "$HTTPS_PROXY" ]; then
    export https_proxy="$HTTPS_PROXY"
    export HTTPS_PROXY="$HTTPS_PROXY"
fi

if [ -n "$NO_PROXY" ]; then
    export no_proxy="$NO_PROXY"
    export NO_PROXY="$NO_PROXY"
fi

# Welcome message
echo "🚀 Universal Development Environment"
echo "Platform: ${DEV_ENV_PLATFORM:-unknown}"
echo "User: $(whoami)"
echo "Working Directory: $(pwd)"
echo ""
echo "Available tools:"
echo "  - Java: $(java -version 2>&1 | head -n 1)"
echo "  - Python: $(python --version)"
echo "  - Node.js: $(node --version 2>/dev/null || echo 'Not available')"
echo "  - Maven: $(mvn --version 2>/dev/null | head -n 1 || echo 'Not available')"
echo "  - Git: $(git --version)"
echo ""
echo "Quick commands:"
echo "  jl    - Start Jupyter Lab"
echo "  gs    - Git status"
echo "  ll    - List files"
echo "  mkcd  - Make directory and cd into it"
echo ""

# Load bash completion if available
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Load local customizations if they exist
if [ -f ~/.bashrc.local ]; then
    . ~/.bashrc.local
fi