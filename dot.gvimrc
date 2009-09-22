" REQUIRED. This makes vim invoke latex-suite when you open a tex file. 
filetype plugin on 

" IMPORTANT: win32 users will need to have 'shellslash' set so that latex 
" can be called correctly. 
set shellslash 

" IMPORTANT: grep will sometimes skip displaying the file name if you 
" search in a singe file. This will confuse latex-suite. Set your grep 
" program to alway generate a file-name. 
set grepprg=grep\ -nH\ $* 

" OPTIONAL: This enables automatic indentation as you type. 
filetype indent on 

" �Ƽ��δĶ��˹�碌�� .tex �ե������ dvi �ե�����˥���ѥ��뤹�륳�ޥ�ɤˡ�Ŭ���֤������Ƥ��������� (Vine Linux 3.1 �ξ��) 
let g:Tex_CompileRule_dvi = 'platex $*' 

" Ʊ�ͤˡ�dvi �ե�����Υӥ塼� 
let g:Tex_ViewRule_dvi = 'dviout' 
"
" ���Ƕػ�
set guicursor=a:blinkon0

" �ե��������
if has('win32')
  set guifont=NF��ȥ䥢�ݥ�:h11:cUNICODE<F14>
  set linespace=1
elseif has('xfontset')
  set guifontset=a14,r14,k14
elseif has('mac')
  set guifont=Monaco:h14
endif

" MacPorts
set macatsui
set antialias
" for use Japanese
set termencoding=japan
set gfw=Osaka-Mono:h12

" ambwidth
set ambwidth=double
