set nocompatible
set number
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set autoindent
set smartindent
syntax on
filetype plugin indent on

augroup dotfiles_go
  autocmd!
  autocmd FileType go setlocal noexpandtab tabstop=4 shiftwidth=4 softtabstop=4
augroup END
