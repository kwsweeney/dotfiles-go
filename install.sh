#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ensure_line() {
  local file="$1"
  local line="$2"

  mkdir -p "$(dirname "$file")"
  touch "$file"

  if ! grep -Fqx "$line" "$file"; then
    printf '\n%s\n' "$line" >> "$file"
  fi
}

ensure_vim_source() {
  local file="$HOME/.vimrc"

  mkdir -p "$(dirname "$file")"
  touch "$file"

  if ! grep -Fq '.vimrc.dotfiles-go' "$file"; then
    printf '\n%s\n' 'source ~/.vimrc.dotfiles-go' >> "$file"
  fi
}

write_goenv() {
  local target="$HOME/.config/go/env"
  local temp_file
  mkdir -p "$(dirname "$target")"
  temp_file="$(mktemp)"
  trap "rm -f -- '$temp_file'" EXIT
  printf 'GOPATH=%s/go\nGOBIN=%s/go/bin\n' "$HOME" "$HOME" > "$temp_file"
  mv "$temp_file" "$target"
  trap - EXIT
}

link_file() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"
  ln -sfn "$source" "$target"
}

link_file "$repo_root/.golang_env" "$HOME/.golang_env"
link_file "$repo_root/.gitconfig" "$HOME/.gitconfig.dotfiles-go"
link_file "$repo_root/.vimrc" "$HOME/.vimrc.dotfiles-go"
write_goenv

ensure_line "$HOME/.bashrc" '[ -f "$HOME/.golang_env" ] && . "$HOME/.golang_env"'
ensure_line "$HOME/.profile" '[ -f "$HOME/.golang_env" ] && . "$HOME/.golang_env"'
ensure_line "$HOME/.zshrc" '[ -f "$HOME/.golang_env" ] && . "$HOME/.golang_env"'

if command -v git >/dev/null 2>&1; then
  git_include_target="$HOME/.gitconfig.dotfiles-go"
  git_include_paths="$(git config --global --path --get-all include.path 2>/dev/null || true)"
  if ! printf '%s\n' "$git_include_paths" | grep -Fqx "$git_include_target"; then
    git config --global --add include.path "$git_include_target"
  fi
fi

managed_vimrc="$HOME/.vimrc.dotfiles-go"
repo_vimrc="$repo_root/.vimrc"
vimrc_link_target="$(readlink "$HOME/.vimrc" 2>/dev/null || true)"

if [ ! -e "$HOME/.vimrc" ] && [ ! -L "$HOME/.vimrc" ]; then
  ln -s "$HOME/.vimrc.dotfiles-go" "$HOME/.vimrc"
elif [ -L "$HOME/.vimrc" ] && [ ! -e "$HOME/.vimrc" ]; then
  rm -f "$HOME/.vimrc"
  ln -s "$HOME/.vimrc.dotfiles-go" "$HOME/.vimrc"
elif [ -L "$HOME/.vimrc" ] && {
  [ "$vimrc_link_target" = "$managed_vimrc" ] ||
    [ "$vimrc_link_target" = "~/.vimrc.dotfiles-go" ] ||
    [ "$vimrc_link_target" = ".vimrc.dotfiles-go" ] ||
    [ "$vimrc_link_target" = "./.vimrc.dotfiles-go" ] ||
    [ "$vimrc_link_target" = "$repo_vimrc" ]
}; then
  ln -sfn "$HOME/.vimrc.dotfiles-go" "$HOME/.vimrc"
elif [ ! -L "$HOME/.vimrc" ]; then
  ensure_vim_source
fi

mkdir -p "$HOME/go/bin" "$HOME/go/pkg" "$HOME/go/src"
