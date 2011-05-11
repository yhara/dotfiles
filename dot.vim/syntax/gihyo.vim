" Vim syntax file
" Language:         Gihyo
" Maintainer:       HARA, Yutaka (yhara/at/kmc.gr.jp)
" URL:              http://mono.kmc.gr.jp/~yhara/
" Latest Revision:  ?
" arch-tag:         ?

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn keyword gihyoTodo      contained TODO FIXME XXX NOTE
syn region  gihyoHeader1    start='^■[^■]' end='$'
syn region  gihyoHeader2    start='^■■[^■]' end='$'
syn region  gihyoHeader3    start='^■■■[^■]' end='$'
syn region  gihyoHeader4    start='^■■■■[^■]' end='$'
syn region  gihyoCaption    start='^●' end='$'
syn region  gihyoList       start='◆list/◆' end='◆/list◆'
syn region  gihyoColumn     start='\v◆/?column/?◆' end='$'

"syn region  gihyoPasteLine start='^ ' end='$'
"syn region  gihyoItemize   start='^*' end='$'
"syn region  gihyoEnumerate start='^#' end='$'
"syn region  gihyoDescription start='^:' end=':'
"syn region  gihyoHref        start='\[\[' end='\]\]'


" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_gihyo_syn_inits")
  if version < 508
    let did_gihyo_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  "HiLink hdPasteLine       Comment
  HiLink gihyoHeader1           Number
  HiLink gihyoHeader2           Comment
  HiLink gihyoHeader3           Identifier
  HiLink gihyoHeader4            Operator
  HiLink gihyoCaption           Operator
  HiLink gihyoList              Underlined
  HiLink gihyoColumn            Operator
"  HiLink gihyoItemize          String
"  HiLink gihyoEnumerate        String
"  HiLink gihyoHref     Underlined
"  HiLink gihyoDescription      Underlined
  HiLink gihyoTodo             Todo

"  HiLink hdComment         Comment
"  HiLink hdDocumentEnd      PreProc
"  HiLink hdDirective       Keyword
"  HiLink hdNodeProperty   Type
"  HiLink hdAnchor          Type
"  HiLink hdAlias           Type
"  HiLink hdDelimiter       Delimiter
"  HiLink hdBlock           Operator
"  HiLink hdOperator        Operator
"  HiLink hdKey     Identifier
"  HiLink hdString          String
"  HiLink hdEscape          SpecialChar
"  HiLink hdSingleEscape   SpecialChar
"  HiLink hdNumber          Number
"  HiLink hdConstant        Constant
"  HiLink hdTimestamp       Number

  delcommand HiLink
endif

let b:current_syntax = "gihyo"

" vim: set sts=2 sw=2:

