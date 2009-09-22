" Vim syntax file
" Language:         ReVIEW
" Maintainer:       HARA, Yutaka (yhara/at/kmc.gr.jp)
" URL:              http://route477.net/
" Latest Revision:  ?
" arch-tag:         ?

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn keyword reviewTodo      contained TODO FIXME XXX NOTE
syn region  reviewHeader    start='^=' end='$'
syn region  reviewList      start='\/\/(em)?list' end='\/\/}'
syn region  reviewItemize   start='^*' end='$'
syn region  reviewEnumerate start='^[1-9]\.' end='$'
syn region  reviewDescription start='^:' end='$'
syn region  reviewInline     start='@<(list|fn|img|table|kw|chap|title|chapref|bou|ruby|ami|b)>{' end='}'

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_review_syn_inits")
  if version < 508
    let did_review_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink reviewHeader           Type
  HiLink reviewList        Comment
  HiLink reviewItemize          String
  HiLink reviewEnumerate        String
  HiLink reviewDescription      Underlined
  HiLink reviewTodo             Todo
  HiLink reviewInline          String

"  HiLink reviewComment         Comment
"  HiLink reviewDocumentEnd      PreProc
"  HiLink reviewDirective       Keyword
"  HiLink reviewNodeProperty   Type
"  HiLink reviewAnchor          Type
"  HiLink reviewAlias           Type
"  HiLink reviewDelimiter       Delimiter
"  HiLink reviewBlock           Operator
"  HiLink reviewOperator        Operator
"  HiLink reviewKey     Identifier
"  HiLink reviewString          String
"  HiLink reviewEscape          SpecialChar
"  HiLink reviewSingleEscape   SpecialChar
"  HiLink reviewNumber          Number
"  HiLink reviewConstant        Constant
"  HiLink reviewTimestamp       Number

  delcommand HiLink
endif

let b:current_syntax = "re"

" vim: set sts=2 sw=2:

