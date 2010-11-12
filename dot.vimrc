"
" vimrc
"

" detecting character encoding
if &encoding !=# 'utf-8'
  set encoding=japan
  set fileencoding=japan
endif
if has('iconv')
  let s:enc_euc = 'euc-jp'
  let s:enc_jis = 'iso-2022-jp'
  " does iconv supports eucJP-ms?
  if iconv("\x87\x64\x87\x6a", 'cp932', 'eucjp-ms') ==# "\xad\xc5\xad\xcb"
    let s:enc_euc = 'eucjp-ms'
    let s:enc_jis = 'iso-2022-jp-3'
  " does iconv supports JISX0213
  elseif iconv("\x87\x64\x87\x6a", 'cp932', 'euc-jisx0213') ==# "\xad\xc5\xad\xcb"
    let s:enc_euc = 'euc-jisx0213'
    let s:enc_jis = 'iso-2022-jp-3'
  endif
  " construct fileencodings
  if &encoding ==# 'utf-8'
    let s:fileencodings_default = &fileencodings
    let &fileencodings = s:enc_jis .','. s:enc_euc .',cp932'
    let &fileencodings = &fileencodings .','. s:fileencodings_default
    unlet s:fileencodings_default
  else
    let &fileencodings = &fileencodings .','. s:enc_jis
    set fileencodings+=utf-8,ucs-2le,ucs-2
    if &encoding =~# '^\(euc-jp\|euc-jisx0213\|eucjp-ms\)$'
      set fileencodings+=cp932
      set fileencodings-=euc-jp
      set fileencodings-=euc-jisx0213
      set fileencodings-=eucjp-ms
      let &encoding = s:enc_euc
      let &fileencoding = s:enc_euc
    else
      let &fileencodings = &fileencodings .','. s:enc_euc
    endif
  endif
  " dispose constants
  unlet s:enc_euc
  unlet s:enc_jis
endif

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

" avoid mistype
set nopaste
abbr lamdba lambda
abbr funciton function
abbr reuqire require 
abbr incldue include
abbr improt import
abbr RUby Ruby

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
:set laststatus=2  "show statusline even there's only one file
:source $VIMRUNTIME/macros/matchit.vim

" TabpageCD
command! -nargs=? TabpageCD
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

source ~/.vimrc.mine
" unite
nnoremap <Space>u   :<C-u>Unite buffer file_mru<Return>
nnoremap <Space>f	  :<C-u>UniteWithBufferDir file<Return>
" nnoremap <silent> <C-n>  :<C-u>Unite buffer <CR>
