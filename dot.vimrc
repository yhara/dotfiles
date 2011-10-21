"
" vimrc
"

" Vundle

set nocompatible               " be iMproved
filetype off                   " required!

set rtp+=~/.vim/vundle.git/ 
call vundle#rc()

" command
" Don't forget to make vimproc after BundleInstall
Bundle 'Shougo/vimproc'
Bundle 'thinca/vim-quickrun'
Bundle 'Shougo/vimshell'

" motion
Bundle 'thinca/vim-poslist'
map <C-i> <Plug>(poslist-prev-pos)
map <C-o> <Plug>(poslist-next-pos)

" input
Bundle 'Align'
Bundle 'tpope/vim-surround'

" filetype
Bundle 'IndentAnything'
Bundle 'tpope/vim-endwise'
Bundle 'tpope/vim-haml'
Bundle 'tpope/vim-rails'
Bundle 'mattn/gist-vim'
Bundle 'ujihisa/shadow.vim'
Bundle 'kchmck/vim-coffee-script'
Bundle 'tpope/vim-markdown'

" unite
Bundle 'Shougo/unite.vim'
Bundle 'ujihisa/unite-colorscheme'
Bundle 'ujihisa/unite-gem'
Bundle 'h1mesuke/unite-outline'
Bundle 'Sixeight/unite-grep'
let g:unite_source_grep_default_opts = '-iRHn'
nnoremap <Space>u   :<C-u>Unite buffer file_mru<Return>
nnoremap <Space>f   :<C-u>UniteWithBufferDir file<Return>
nnoremap <Space>r   :<C-u>Unite file_rec<Return>
nnoremap <Space>o   :<C-u>Unite outline<Return>

filetype plugin indent on     " required!

" -- Vundle

" coding
set encoding=utf-8

" settings for multibyte chars
if exists("&ambiwidth")
  set ambiwidth=single
endif

if &t_Co > 1
  syntax enable
endif

filetype on
filetype indent on
filetype plugin on

set expandtab

augroup filetypedetect
  autocmd! BufNewFile,BufRead *.rhtml setf html
  autocmd! BufNewFile,BufRead *.hd setf hd
augroup END

" anagol
autocmd BufRead,BufNewFile *anagol/* setl bin noeol

" mouse
set mouse=a
set ttymouse=xterm2

" parentheses
set showmatch

" insert current time
function! GetCurrentTime()
  return strftime(" @%H:%M", localtime())
endfunction
noremap <F2> a<C-R>=GetCurrentTime()<CR><Esc>

" change current encoding
nmap <silent> eu :set fenc=utf-8<CR>
nmap <silent> ee :set fenc=euc-jp<CR>
nmap <silent> es :set fenc=cp932<CR>
" reopen with different encoding
nmap <silent> eru :e ++enc=utf-8 %<CR>
nmap <silent> ere :e ++enc=euc-jp %<CR>
nmap <silent> ers :e ++enc=cp932 %<CR>

" only physical movements
nnoremap j gj
nnoremap k gk

" open another buffer in vsplit window
nnoremap <C-w>X :<C-u>vsplit <Bar> edit #"

" kill K
nnoremap K <Esc>

" avoid mistype
set nopaste
inoreabbr lamdba lambda
inoreabbr funciton function
inoreabbr reuqire require 
inoreabbr incldue include
inoreabbr improt import
inoreabbr RUby Ruby

" do not invoke ime
set iminsert=0
set imsearch=0

" delete text before start point
set backspace=2

" vbell
set visualbell

" open/reload .vimrc
nnoremap <SPACE>.       :<C-u>edit $MYVIMRC<CR>
nnoremap <SPACE>s.      :<C-u>source $MYVIMRC<CR>

" escape '/' when searching 
cnoremap <expr> / getcmdtype() == '/' ? '\/' : '/'

" super-automatic saving
inoremap <ESC>  <ESC>:<C-u>w<Return>
"autocmd InsertLeave * silent! write

" q to close help : http://d.hatena.ne.jp/mickey24/20090429/1240992099
autocmd FileType help nnoremap <buffer> q <C-w>c

" do not create swap files (only in /tmp)
set directory-=.

" nohighlight
nnoremap <SPACE>n       :<C-u>nohlsearch<CR>

" open the directory of the current buffer
nnoremap <SPACE>e       :<C-u>e %:h<CR>

" consistent Y (yank to the end of line)
nnoremap Y y$

" lemon
set nopaste
set autoindent
set hlsearch
set sw=2
set sts=2
set ts=8
set et
set modeline
set modelines=5
syntax on
set laststatus=2  "show statusline even there's only one file
source $VIMRUNTIME/macros/matchit.vim

" TabpageCD
command! -nargs=? -complete=file TabpageCD
      \   execute 'cd' fnameescape(<q-args>)
      \ | let t:cwd = getcwd()

autocmd TabEnter *
      \   if !exists('t:cwd')
      \ |   let t:cwd = getcwd()
      \ | endif
      \ | execute 'cd' fnameescape(t:cwd)

" git-vim
let g:git_command_edit = 'rightbelow vnew'
nnoremap <Leader>gc :<C-u>GitCommit -v<Enter>
autocmd FileType git-status,git-log nnoremap <buffer> q <C-w>c

if filereadable(expand('~/.vimrc.mine'))
  source ~/.vimrc.mine
endif

