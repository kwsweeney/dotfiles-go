#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [ "$expected" != "$actual" ]; then
    printf 'assertion failed: %s\nexpected: %s\nactual: %s\n' "$message" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_contains() {
  local needle="$1"
  local file="$2"

  if ! grep -Fq "$needle" "$file"; then
    printf 'assertion failed: %s missing from %s\n' "$needle" "$file" >&2
    exit 1
  fi
}

run_install() {
  local home_dir="$1"
  HOME="$home_dir" "$repo_root/install.sh"
}

case_missing_vimrc() {
  local home_dir
  home_dir="$(mktemp -d)"
  run_install "$home_dir"
  assert_eq "$home_dir/.vimrc.dotfiles-go" "$(readlink "$home_dir/.vimrc")" "missing vimrc should become managed symlink"
  [ ! -L "$home_dir/.vimrc.dotfiles-go" ]
}

case_broken_vimrc_symlink() {
  local home_dir
  home_dir="$(mktemp -d)"
  ln -s "$home_dir/missing-vimrc" "$home_dir/.vimrc"
  run_install "$home_dir"
  assert_eq "$home_dir/.vimrc.dotfiles-go" "$(readlink "$home_dir/.vimrc")" "broken vimrc symlink should be repaired"
}

case_regular_vimrc() {
  local home_dir
  home_dir="$(mktemp -d)"
  printf 'set number\n' > "$home_dir/.vimrc"
  run_install "$home_dir"
  assert_contains 'source ~/.vimrc.dotfiles-go' "$home_dir/.vimrc"
}

case_unrelated_vimrc_symlink() {
  local home_dir
  home_dir="$(mktemp -d)"
  printf 'set hlsearch\n' > "$home_dir/custom-vimrc"
  ln -s "$home_dir/custom-vimrc" "$home_dir/.vimrc"
  run_install "$home_dir"
  assert_eq "$home_dir/custom-vimrc" "$(readlink "$home_dir/.vimrc")" "unrelated vimrc symlink should stay untouched"
  if grep -Fq '.vimrc.dotfiles-go' "$home_dir/custom-vimrc"; then
    printf 'assertion failed: unrelated vimrc symlink target was modified\n' >&2
    exit 1
  fi
}

case_goenv_merge() {
  local home_dir
  home_dir="$(mktemp -d)"
  mkdir -p "$home_dir/.config/go"
  cat > "$home_dir/.config/go/env" <<'EOT'
GOFLAGS=-mod=mod
GOPATH=/old/go
GOBIN=/old/go/bin
EOT
  run_install "$home_dir"
  assert_contains 'GOFLAGS=-mod=mod' "$home_dir/.config/go/env"
  assert_contains "GOPATH=$home_dir/go" "$home_dir/.config/go/env"
  assert_contains "GOBIN=$home_dir/go/bin" "$home_dir/.config/go/env"
}

case_goenv_symlink_merge() {
  local home_dir
  home_dir="$(mktemp -d)"
  mkdir -p "$home_dir/.config/go"
  cat > "$home_dir/go-env-source" <<'EOT'
GOFLAGS=-mod=mod
GOPATH=/old/go
EOT
  ln -s "$home_dir/go-env-source" "$home_dir/.config/go/env"
  run_install "$home_dir"
  assert_contains 'GOFLAGS=-mod=mod' "$home_dir/.config/go/env"
  assert_contains "GOPATH=$home_dir/go" "$home_dir/.config/go/env"
  assert_contains "GOBIN=$home_dir/go/bin" "$home_dir/.config/go/env"
}

case_matching_managed_symlink() {
  local home_dir
  home_dir="$(mktemp -d)"
  ln -s "$repo_root/.golang_env" "$home_dir/.golang_env"
  run_install "$home_dir"
  assert_eq "$repo_root/.golang_env" "$(readlink "$home_dir/.golang_env")" "matching managed symlink should remain intact"
}

case_missing_vimrc
case_broken_vimrc_symlink
case_regular_vimrc
case_unrelated_vimrc_symlink
case_goenv_merge
case_goenv_symlink_merge
case_matching_managed_symlink

echo 'install.sh tests passed'
