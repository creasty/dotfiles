; The keywords <CR> closes a block with (user.plugin.treesitter.endwise)

((if_statement "then" @cursor) @endable @indent (#set! endwise.end "fi"))
((do_group "do" @cursor) @endable @indent (#set! endwise.end "done"))
((case_statement "in" @cursor) @endable @indent (#set! endwise.end "esac"))

((ERROR ("case" @indent . (_) . "in" @cursor)) (#set! endwise.end "esac"))
