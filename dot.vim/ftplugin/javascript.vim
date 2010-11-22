" js.vim
"
set ts=2 sw=2 sts=0
set expandtab

"map ; <Esc>
"imap ; <Esc>

"map <F14> <CR>
"imap <F14> <CR>

" \ -> function(  from http://vim-users.jp/2010/07/hack160/
inoremap <buffer> <expr> \  smartchr#one_of('function(', '\')

" = -> ' = '
inoremap <buffer> <expr> = "smartchr#one_of(' = ', ' == ', ' === ', '=')
