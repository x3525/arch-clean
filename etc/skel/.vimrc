set nocompatible
set noloadplugins

autocmd BufReadPost * if line("'\"") >= 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif

filetype indent on
syntax on

set autoindent
set backspace=indent,eol,start
set confirm
set encoding=UTF-8
set expandtab
set ignorecase
set incsearch
set laststatus=2
set list
set listchars=trail:^,tab:>-,extends:>,precedes:<,nbsp:~
set mouse=
set nobackup
set noshowmatch
set scrolloff=999
set shiftwidth=4
set shortmess=finxoOstTI
set showmode
set smartcase
set smartindent
set softtabstop=4
set whichwrap+=<,>,h,l,[,]
