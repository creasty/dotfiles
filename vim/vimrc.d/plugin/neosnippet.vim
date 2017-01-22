let g:neosnippet#disable_select_mode_mappings = 0
let g:neosnippet#enable_snipmate_compatibility = 1
let g:neosnippet#snippets_directory = g:env.path.snippets
let g:neosnippet#disable_runtime_snippets = { '_' : 1 }

" remove placeholders (hidden markers) before saving
autocmd vimrc BufWritePre *
  \ exec '%s/<`\d\+:\?[^>]*`>//ge'
