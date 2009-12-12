if exists("did_load_filetypes")
  finish
endif
augroup filetypedetect
  au! BufRead,BufNewFile *.re           setfiletype review
  au! BufRead,BufNewFile *.less         setfiletype css
  au! BufRead,BufNewFile *.scala        setfiletype scala
  au! BufRead,BufNewFile *.treetop      setfiletype treetop

  au! BufRead,BufNewFile *.mab          setfiletype ruby
  au! BufRead,BufNewFile *.ges          setfiletype ruby
  au! BufRead,BufNewFile *.arc          setfiletype lisp
  au! BufRead,BufNewFile *.nu           setfiletype lisp

  au! BufRead,BufNewFile *.tex          lnoremap _ \
augroup END
