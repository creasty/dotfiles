; The keywords <CR> closes a block with (user.plugin.treesitter.endwise)

((function_declaration parameters: (_) @cursor) @endable @indent (#set! endwise.end "end"))
((function_definition parameters: (_) @cursor) @endable @indent (#set! endwise.end "end"))
((while_statement "do" @cursor) @endable @indent (#set! endwise.end "end"))
((for_statement "do" @cursor) @endable @indent (#set! endwise.end "end"))
((if_statement "then" @cursor) @endable @indent (#set! endwise.end "end"))
((do_statement "do" @cursor) @endable @indent (#set! endwise.end "end"))

((ERROR ("function" . (_)? . (parameters) @cursor) @indent) (#set! endwise.end "end"))
((ERROR ("do" @cursor @indent)) (#set! endwise.end "end"))
((ERROR ("while" @indent . (_) . "do" @cursor)) (#set! endwise.end "end"))
((ERROR ("for" @indent . [(for_generic_clause) (for_numeric_clause)] . "do" @cursor)) (#set! endwise.end "end"))
((ERROR ("if" @indent . (_) . "then" @cursor)) (#set! endwise.end "end"))
