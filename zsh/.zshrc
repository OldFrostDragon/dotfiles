[[ $TERM == "dumb" ]] && unsetopt zle && PS1='$ ' && return

export PATH="$HOME/.poetry/bin:$PATH"

if [ -f pyenv ]; then
  eval "$(pyenv init -)"
fi

# pnpm
if [[ "$(uname -s)" == "Darwin" ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
  export PATH="$PNPM_HOME:$PATH"
fi
# pnpm end