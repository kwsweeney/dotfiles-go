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

next_backup_path() {
  local target="$1"
  local backup_target="$target.dotfiles-go.bak"
  local backup_index=0

  while [ -e "$backup_target" ] || [ -L "$backup_target" ]; do
    backup_index=$((backup_index + 1))
    backup_target="$target.dotfiles-go.bak.$backup_index"
  done

  printf '%s\n' "$backup_target"
}

backup_existing_path() {
  local target="$1"
  local backup_target

  backup_target="$(next_backup_path "$target")"
  mv "$target" "$backup_target"
}

install_managed_file() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ]; then
    if [ -e "$target" ] && cmp -s "$source" "$target"; then
      return 0
    fi
    backup_existing_path "$target"
  elif [ -e "$target" ] && ! cmp -s "$source" "$target"; then
    backup_existing_path "$target"
  fi

  cp "$source" "$target"
}

write_goenv() {
  local target="$HOME/.config/go/env"
  local target_dir
  local temp_file

  target_dir="$(dirname "$target")"
  mkdir -p "$target_dir"
  temp_file="$(mktemp -p "$target_dir" env.tmp.XXXXXX)"

  if [ -L "$target" ]; then
    if [ -e "$target" ]; then
      grep -vE '^(GOPATH|GOBIN)=' "$target" > "$temp_file" || true
    fi
    backup_existing_path "$target"
  elif [ -f "$target" ]; then
    grep -vE '^(GOPATH|GOBIN)=' "$target" > "$temp_file" || true
  fi

  printf 'GOPATH=%s/go\nGOBIN=%s/go/bin\n' "$HOME" "$HOME" >> "$temp_file"
  mv "$temp_file" "$target"
}

install_managed_file "$repo_root/.golang_env" "$HOME/.golang_env"
install_managed_file "$repo_root/.gitconfig" "$HOME/.gitconfig.dotfiles-go"
install_managed_file "$repo_root/.vimrc" "$HOME/.vimrc.dotfiles-go"
write_goenv

ensure_line "$HOME/.bashrc" '[ -f "$HOME/.golang_env" ] && . "$HOME/.golang_env"'
ensure_line "$HOME/.profile" '[ -f "$HOME/.golang_env" ] && . "$HOME/.golang_env"'
ensure_line "$HOME/.zshrc" '[ -f "$HOME/.golang_env" ] && . "$HOME/.golang_env"'

if command -v git >/dev/null 2>&1; then
  git_include_target="$HOME/.gitconfig.dotfiles-go"
  git_include_paths="$(git config --global --get-all include.path 2>/dev/null || true)"
  if ! printf '%s\n' "$git_include_paths" | grep -Fqx "$git_include_target" &&
    ! printf '%s\n' "$git_include_paths" | grep -Fqx '~/.gitconfig.dotfiles-go'; then
    git config --global --add include.path "$git_include_target"
  fi
fi

managed_vimrc="$HOME/.vimrc.dotfiles-go"
repo_vimrc="$repo_root/.vimrc"
vimrc_link_target="$(readlink "$HOME/.vimrc" 2>/dev/null || true)"

if [ ! -e "$HOME/.vimrc" ] && [ ! -L "$HOME/.vimrc" ]; then
  ln -s "$managed_vimrc" "$HOME/.vimrc"
elif [ -L "$HOME/.vimrc" ]; then
  if [ ! -e "$HOME/.vimrc" ]; then
    rm -f "$HOME/.vimrc"
    ln -s "$managed_vimrc" "$HOME/.vimrc"
  elif [ "$vimrc_link_target" = "$managed_vimrc" ] ||
    [ "$vimrc_link_target" = '~/.vimrc.dotfiles-go' ] ||
    [ "$vimrc_link_target" = '.vimrc.dotfiles-go' ] ||
    [ "$vimrc_link_target" = './.vimrc.dotfiles-go' ] ||
    [ "$vimrc_link_target" = "$repo_vimrc" ]; then
    ln -sfn "$managed_vimrc" "$HOME/.vimrc"
  fi
else
  ensure_vim_source
fi

mkdir -p "$HOME/go/bin" "$HOME/go/pkg" "$HOME/go/src"
