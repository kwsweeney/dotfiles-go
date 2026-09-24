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

write_goenv() {
  local target="$HOME/.config/go/env"
  mkdir -p "$(dirname "$target")"
  sed "s|__HOME__|$HOME|g" "$repo_root/.config/go/env" > "$target"
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
if [ -f "$HOME/.zshrc" ]; then
  ensure_line "$HOME/.zshrc" '[ -f "$HOME/.golang_env" ] && . "$HOME/.golang_env"'
fi

if command -v git >/dev/null 2>&1; then
  if ! git config --global --get-all include.path | grep -Fqx "$HOME/.gitconfig.dotfiles-go"; then
    git config --global --add include.path "$HOME/.gitconfig.dotfiles-go"
  fi
fi

ensure_line "$HOME/.vimrc" 'source ~/.vimrc.dotfiles-go'

mkdir -p "$HOME/go/bin" "$HOME/go/pkg" "$HOME/go/src"
