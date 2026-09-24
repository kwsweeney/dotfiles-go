# dotfiles-go

Go dotfiles for Codespaces.

This repository provides a small Go-focused bootstrap for GitHub Codespaces:

- shell environment defaults for `GOPATH`, `GOBIN`, and `PATH`
- a Go toolchain env file in `~/.config/go/env`
- shared Git defaults through `.gitconfig`
- shared Vim defaults with Go-specific tab settings

When this repository is configured as your Codespaces dotfiles repository, GitHub Codespaces will automatically run the root `install.sh` during setup.
