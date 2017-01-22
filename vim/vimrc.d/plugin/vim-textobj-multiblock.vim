let g:textobj_multiblock_blocks = [
  \ [ '(', ')' ],
  \ [ '[', ']' ],
  \ [ '{', '}' ],
  \ [ '<', '>' ],
  \ [ '"', '"' ],
  \ [ "'", "'" ],
  \ [ '「', '」' ],
  \ [ '（', '）' ],
\ ]

omap ab <Plug>(textobj-multiblock-a)
omap ib <Plug>(textobj-multiblock-i)
xmap ab <Plug>(textobj-multiblock-a)
xmap ib <Plug>(textobj-multiblock-i)
