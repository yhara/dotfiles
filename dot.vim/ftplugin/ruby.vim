" ruby.vim
"
set ts=2 sw=2 sts=0
set expandtab

"map ; <Esc>
"imap ; <Esc>

"map <F14> <CR>
"imap <F14> <CR>

" {{ -> #{ (http://vim-users.jp/2010/03/hack131/)
inoremap <expr> <buffer> {  smartchr#loop('{', '#{', '{{{')

" = -> ' = '
inoremap <buffer> <expr> = "smartchr#one_of(' = ', ' == ', ' === ', '=')
