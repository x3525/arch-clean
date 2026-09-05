filetype indent on
syntax off

augroup jumpCursor
    autocmd!
    autocmd BufReadPost *
                \ if line("'\"") >= 1 && line("'\"") <= line("$")
                \ | execute "normal! g`\""
                \ | endif
augroup END

" Switch them off.
set nobackup
set noloadplugins
set noshowmatch

" Switch them on.
set autoindent
set backspace=indent,eol,start
set encoding=utf-8
set expandtab
set ignorecase
set incsearch
set laststatus=2
set list
set listchars=tab:>-,trail:^,extends:>,precedes:<
set mouse=
set scrolloff=999
set shiftwidth=0
set shortmess=oOstT
set showmode
set smartcase
set smartindent
set softtabstop=-1
set tabstop=4
set ttyfast
set whichwrap=<,>,[,]
set wrap
