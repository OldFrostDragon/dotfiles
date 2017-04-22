#!/bin/bash

# copied from https://github.com/holman/dotfiles/blob/master/script/bootstrap
DOTFILES_ROOT=$(pwd -P)

set -e

echo ''

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
    ln -s "$1" "$2"
    success "linked $1 to $2"
  fi
}

install_dotfiles () {
  info 'installing dotfiles'

  local overwrite_all=false backup_all=false skip_all=false
  mkdir -p "$HOME/.oh-my-zsh/themes/"
  mkdir -p "$HOME/.config/QtProject/qtcreator/styles/"
  mkdir -p "$HOME/.config/sublime-text-3/Packages/User/"
  mkdir -p "$HOME/.fonts/"
  mkdir -p "$HOME/.config/mc"

  dst="$HOME/.$(basename "${src%.*}")"
  link_file "$DOTFILES_ROOT/git/.gitconfig" "$HOME/.gitconfig"
  link_file "$DOTFILES_ROOT/git/.gitexcludes" "$HOME/.gitexcludes"
  link_file "$DOTFILES_ROOT/tig/.tigrc" "$HOME/.tigrc"
  link_file "$DOTFILES_ROOT/vim/.vimrc" "$HOME/.vimrc"
  link_file "$DOTFILES_ROOT/vim/.vim" "$HOME/.vim"
  link_file "$DOTFILES_ROOT/zsh/.zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES_ROOT/zsh/agnoster-mod.zsh-theme" "$HOME/.oh-my-zsh/themes/agnoster-mod.zsh-theme"
  link_file "$DOTFILES_ROOT/qt-creator/monokai_copy.xml" "$HOME/.config/QtProject/qtcreator/styles/monokai_copy.xml"
  link_file "$DOTFILES_ROOT/qt-creator/monokai_night_shift_v2_copy.xml" "$HOME/.config/QtProject/qtcreator/styles/monokai_night_shift_v2_copy.xml"
  link_file "$DOTFILES_ROOT/sublime-text-3" "$HOME/.config/sublime-text-3/Packages/User"
  link_file "$DOTFILES_ROOT/mc" "$HOME/.config/mc"
  link_file "$DOTFILES_ROOT/tmux/.tmux.conf" "$HOME/.tmux.conf"

  # create symlinks to bin scripts
  for src in $(find -H "$DOTFILES_ROOT/bin" -maxdepth 1 -type f)
  do
    file_from_src=$(basename $src)
    dst="/usr/local/bin/$file_from_src"
    link_file "$src" "$dst"
  done

  info '    done'
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
  info 'installing fonts'
  find "$DOTFILES_ROOT/fonts" -name "*.ttf" -exec cp -f {} $HOME/.fonts \;
  fc-cache -fv > /dev/null &
  show_progress $!
  info '    done'
}

install_zsh_plugins() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
        info 'Install zsh-autosuggestions'
        git clone git://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
        info '    done'
    fi

    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
        info 'Install zsh-syntax-highlighting'
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
        info '    done'
    fi
  fi
}

install_dotfiles
install_fonts
install_zsh_plugins
