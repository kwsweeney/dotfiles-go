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
  local home_escaped="${HOME//\\/\\\\}"
  local temp_file
  home_escaped="${home_escaped//&/\\&}"
  mkdir -p "$(dirname "$target")"
  temp_file="$(mktemp "${target}.tmp.XXXXXX")"
  sed "s|__HOME__|$home_escaped|g" "$repo_root/.config/go/env" > "$temp_file"
  mv "$temp_file" "$target"
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
  git_include_paths="$(git config --global --get-all include.path 2>/dev/null || true)"
  if ! printf '%s\n' "$git_include_paths" | grep -Fqx "$HOME/.gitconfig.dotfiles-go"; then
    git config --global --add include.path "$HOME/.gitconfig.dotfiles-go"
  fi
fi

if [ -e "$HOME/.vimrc" ] && [ "$HOME/.vimrc" -ef "$HOME/.vimrc.dotfiles-go" ]; then
  :
else
  ensure_vim_source
fi

mkdir -p "$HOME/go/bin" "$HOME/go/pkg" "$HOME/go/src"
