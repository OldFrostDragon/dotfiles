#!/bin/bash

set -e

DOTFILES_ROOT=$(pwd -P)

OS_IS_DARWIN=false
if [ "$(uname -s)" == "Darwin" ]; then
    OS_IS_DARWIN=true
fi

# copied from https://github.com/holman/dotfiles/blob/master/script/bootstrap

echo ''

log_action () {
  printf "\r  [ \033[00;34mDO\033[0m ] $1\n"
}

info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
  printf "\r  [ \033[0;33m??\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

link_file () {
  local src=$1 dst=$2

  local overwrite= backup= skip=
  local action=

  if [ -f "$dst" -o -d "$dst" -o -L "$dst" ]
  then

    if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]
    then

      local currentSrc="$(readlink $dst)"

      if [ "$currentSrc" == "$src" ]
      then

        skip=true;

      else

        user "File already exists: $dst ($(basename "$src")), what do you want to do?\n\
        [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
        read -n 1 action

        case "$action" in
          o )
            overwrite=true;;
          O )
            overwrite_all=true;;
          b )
            backup=true;;
          B )
            backup_all=true;;
          s )
            skip=true;;
          S )
            skip_all=true;;
          * )
            ;;
        esac

      fi

    fi

    overwrite=${overwrite:-$overwrite_all}
    backup=${backup:-$backup_all}
    skip=${skip:-$skip_all}

    if [ "$overwrite" == "true" ]
    then
      rm -rf "$dst"
      success "removed $dst"
    fi

    if [ "$backup" == "true" ]
    then
      mv "$dst" "${dst}.backup"
      success "moved $dst to ${dst}.backup"
    fi

    if [ "$skip" == "true" ]
    then
      success "skipped $src"
    fi
  fi

  if [ "$skip" != "true" ]  # "false" or empty
  then
    target_dir=$(dirname "$2")
    mkdir -p "$target_dir"
    ln -s "$1" "$2"
    success "linked $1 to $2"
  fi
}

show_progress () {
  pid=$1
  spin='-\|/'

  i=0
  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    printf "\r${spin:$i:1}"
    sleep .1
  done
}

install_fonts () {
  log_action 'Installing fonts...'
  
  FONT_DIR="$HOME/.fonts"
  if $OS_IS_DARWIN; then
    FONT_DIR="$HOME/Library/Fonts"
  fi
  
  mkdir -p "$FONT_DIR"
  find "$DOTFILES_ROOT/fonts" \( -name '*.ttf' -o -name '*.otf' \) -exec cp -f {} "$FONT_DIR" \;
  
  if ! $OS_IS_DARWIN; then
    fc-cache -fv > /dev/null &
    show_progress $!
  fi
  
  success 'Fonts installed.'
}

install_dotfiles () {
  log_action 'Installing dotfiles...'

  local overwrite_all=false backup_all=false skip_all=false

  link_file "$DOTFILES_ROOT/git/.gitconfig" "$HOME/.gitconfig"
  link_file "$DOTFILES_ROOT/git/.gitexcludes" "$HOME/.gitexcludes"
  link_file "$DOTFILES_ROOT/tig/.tigrc" "$HOME/.tigrc"
  link_file "$DOTFILES_ROOT/vim/.vimrc" "$HOME/.vimrc"
  link_file "$DOTFILES_ROOT/vim/.vim" "$HOME/.vim"
  link_file "$DOTFILES_ROOT/qt-creator/monokai_night_shift_v3.xml" "$HOME/.config/QtProject/qtcreator/styles/monokai_night_shift_v3.xml"
  link_file "$DOTFILES_ROOT/mc" "$HOME/.config/mc"
  link_file "$DOTFILES_ROOT/mc/catppuccin.ini" "$HOME/.local/share/mc/skins/catppuccin.ini"
  link_file "$DOTFILES_ROOT/tmux/.tmux.conf" "$HOME/.tmux.conf"
  link_file "$DOTFILES_ROOT/kitty.conf" "$HOME/.config/kitty/kitty.conf"
  link_file "$DOTFILES_ROOT/fish/config.fish" "$HOME/.config/fish/config.fish"
  link_file "$DOTFILES_ROOT/fish/fish_plugins" "$HOME/.config/fish/fish_plugins"

  # macos uses zsh by default. Make it compatible with emacs
  if $OS_IS_DARWIN; then
    link_file "$DOTFILES_ROOT/zsh/.zshrc" "$HOME/.zshrc"
  fi
  success 'All done'
  echo ''
}

install_fisher() {
    log_action "Installing Fisher..."

    # Install Fisher if not already installed
    local fisher_file="$HOME/.config/fish/functions/fisher.fish"
    if [ ! -f "$fisher_file" ]; then
        fish -c "curl --proto =https --tlsv1.2 -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher"
        success "Fisher installed."
    else
        success "Fisher is already installed. Nothing to do."
    fi

    echo ''
}

# Run the function
install_fisher

install_dotfiles
install_fonts
