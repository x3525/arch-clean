unlet! skip_defaults_vim
source $VIMRUNTIME/defaults.vim

call plug#begin()
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    Plug 'rust-lang/rust.vim'
call plug#end()

syntax on
filetype plugin indent on

let &t_EI = "\e[2 q"
let &t_SR = "\e[2 q"
let &t_SI = "\e[2 q"

set backspace=indent,eol,start
set confirm
set encoding=UTF-8
set expandtab
set ignorecase
set incsearch
set laststatus=2
set list
set listchars=tab:>-,trail:^,extends:>,precedes:<,nbsp:~
set mouse=
set nobackup
set nocompatible
set noshowmatch
set scrolloff=0
set shiftwidth=4
set showmode
set smartcase
set smartindent
set softtabstop=4
set whichwrap+=<,>,h,l,[,]
