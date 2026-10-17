; The keywords <CR> closes a block with (user.plugin.treesitter.endwise)

((if_statement condition: (_) @cursor) @endable @indent (#set! endwise.end "endif"))
((for_loop iter: (_) @cursor) @indent (#set! endwise.end "endfor"))
((while_loop condition: (_) @cursor) @indent (#set! endwise.end "endwhile"))
; `function` ends with `endfunction`, `func` with `endfunc`...
((function_definition "function" @indent (function_declaration parameters: (_) @cursor) . ["abort" "closure" "dict" "range"]* @cursor) @endable (#set! endwise.end "end") (#set! endwise.suffix "indent") (#set! endwise.end_type "endfunction"))
((try_statement "try" @cursor) @endable @indent (#set! endwise.end "endtry"))

((ERROR ("if" @indent . (_) @cursor)) (#set! endwise.end "endif"))
((ERROR ("for" @indent . (_) . "in" . (_) @cursor)) (#set! endwise.end "endfor"))
((ERROR ("while" @indent . (_) @cursor)) (#set! endwise.end "endwhile"))
((ERROR ("function" @indent (bang)? . (function_declaration parameters: (_) @cursor) ["abort" "closure" "dict" "range"]* @cursor)) (#set! endwise.end "end") (#set! endwise.suffix "indent"))
((ERROR ("try" @indent @cursor)) (#set! endwise.end "endtry"))
