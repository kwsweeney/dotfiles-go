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
  local target_dir
  local temp_file
  target_dir="$(dirname "$target")"
  mkdir -p "$target_dir"
  temp_file="$(mktemp "$target_dir/env.tmp.XXXXXX")"
  if ! printf 'GOPATH=%s/go\nGOBIN=%s/go/bin\n' "$HOME" "$HOME" > "$temp_file"; then
    rm -f -- "$temp_file"
    exit 1
  fi

  if ! mv "$temp_file" "$target"; then
    rm -f -- "$temp_file"
    exit 1
  fi
}

link_file() {
  local source="$1"
  local target="$2"
  local backup_target="$target.dotfiles-go.bak"
  local backup_index=0

  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    while [ -e "$backup_target" ] || [ -L "$backup_target" ]; do
      backup_index=$((backup_index + 1))
      backup_target="$target.dotfiles-go.bak.$backup_index"
    done
    mv "$target" "$backup_target"
  fi
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
  ln -s "$HOME/.vimrc.dotfiles-go" "$HOME/.vimrc"
elif [ -L "$HOME/.vimrc" ]; then
  if [ ! -e "$HOME/.vimrc" ]; then
    rm -f "$HOME/.vimrc"
    ln -s "$HOME/.vimrc.dotfiles-go" "$HOME/.vimrc"
  elif [ "$vimrc_link_target" = "$managed_vimrc" ] ||
    [ "$vimrc_link_target" = "~/.vimrc.dotfiles-go" ] ||
    [ "$vimrc_link_target" = ".vimrc.dotfiles-go" ] ||
    [ "$vimrc_link_target" = "./.vimrc.dotfiles-go" ] ||
    [ "$vimrc_link_target" = "$repo_vimrc" ]; then
    ln -sfn "$HOME/.vimrc.dotfiles-go" "$HOME/.vimrc"
  fi
else
  ensure_vim_source
fi

mkdir -p "$HOME/go/bin" "$HOME/go/pkg" "$HOME/go/src"
