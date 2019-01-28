" https://pocke.hatenablog.com/entry/2019/01/02/155421
syn match goExtIfErr "\v^\s*if\s+err\s*\!\=\s*nil\s*\{\s*\_$%(.*\n){,2}\_.\s*return%(\s+nil,)*\s+.+\_$\_.\s*\}"
hi link goExtIfErr NonText
