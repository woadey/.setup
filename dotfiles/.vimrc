syntax on

" Lines
set nu
set relativenumber
set nowrap

" Tabs
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent

" Search
set smartcase
set incsearch

" Scroll
set scrolloff=8

" Keeps Buffer Open
set hidden

" History
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile

" Sound
set noerrorbells
set vb
set t_vb=

" Plugins
call plug#begin('~/.vim/plugged')
Plug 'mbbill/undotree'
Plug 'https://github.com/joshdick/onedark.vim.git'
Plug 'https://github.com/ycm-core/YouCompleteMe.git'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
call plug#end()

colorscheme onedark
