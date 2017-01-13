set completeopt& completeopt-=preview

let g:neocomplete#enable_at_startup = 1
let g:neocomplete#enable_smart_case = 1
let g:neocomplete#disable_auto_complete = 0
let g:neocomplete#enable_auto_select = 1
let g:neocomplete#enable_insert_char_pre = 1
let g:neocomplete#sources#syntax#min_keyword_length = 3
let g:neocomplete#sources#buffer#disabled_pattern = '\.log\|\.log\.\|\.jax'
let g:neocomplete#lock_buffer_name_pattern = '\.log\|\.log\.\|.*quickrun.*\|.jax'

let g:neocomplete#sources#dictionary#dictionaries = {
  \ 'default':    '',
  \ 'vimshell':   $HOME . '/.vimshell_hist',
  \ 'ruby':       g:env.path.dict . '/ruby.dict',
  \ 'java':       g:env.path.dict . '/java.dict',
  \ 'javascript': g:env.path.dict . '/javascript.dict',
  \ 'coffee':     g:env.path.dict . '/javascript.dict',
  \ 'html':       g:env.path.dict . '/html.dict',
  \ 'php':        g:env.path.dict . '/php.dict',
  \ 'objc':       g:env.path.dict . '/objc.dict',
  \ 'swift':      g:env.path.dict . '/swift.dict',
  \ 'perl':       g:env.path.dict . '/perl.dict',
  \ 'scala':      g:env.path.dict . '/scala.dict',
\ }

" keyword patterns
let g:neocomplete#keyword_patterns = get(g:, 'neocomplete#keyword_patterns', {})
let g:neocomplete#keyword_patterns._ = '\h\w*'
let g:neocomplete#keyword_patterns.perl = '\h\w*->\h\w*\|\h\w*::\w*'

" input patterns
let g:neocomplete#sources#omni#input_patterns = get(g:, 'neocomplete#sources#omni#input_patterns', {})
let g:neocomplete#sources#omni#input_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
let g:neocomplete#sources#omni#input_patterns.c = '[^.[:digit:] *\t]\%(\.\|->\)'
let g:neocomplete#sources#omni#input_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\|\h\w*::'
let g:neocomplete#sources#omni#input_patterns.go = '[^.[:digit:] *\t]\.\%(\w\|\/\)*'
let g:neocomplete#sources#omni#input_patterns.ruby = '[^. *\t]\.\h\w*\|\h\w*::'
let g:neocomplete#sources#omni#input_patterns.typescript = '\h\w*\|[^. \t]\.\w*'

" omni
let g:neocomplete#force_overwrite_completefunc = 1
let g:neocomplete#force_omni_input_patterns = get(g:, 'neocomplete#force_omni_input_patterns', {})
let g:neocomplete#force_omni_input_patterns.c = '[^.[:digit:] *\t]\%(\.\|->\)\w*'
let g:neocomplete#force_omni_input_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\w*\|\h\w*::\w*'
let g:neocomplete#force_omni_input_patterns.objc = '[^.[:digit:] *\t]\%(\.\|->\)\w*'
let g:neocomplete#force_omni_input_patterns.objcpp = '[^.[:digit:] *\t]\%(\.\|->\)\w*\|\h\w*::\w*'

" clang
let g:clang_complete_auto = 0
let g:clang_auto_select = 0
let g:clang_use_library = 1

" omni completion
autocmd vimrc FileType css
  \ setlocal omnifunc=csscomplete#CompleteCSS
autocmd vimrc FileType html,markdown
  \ setlocal omnifunc=htmlcomplete#CompleteTags
autocmd vimrc FileType javascript
  \ setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd vimrc FileType python
  \ setlocal omnifunc=pythoncomplete#Complete
autocmd vimrc FileType xml
  \ setlocal omnifunc=xmlcomplete#CompleteTags
autocmd vimrc FileType go
  \ setlocal omnifunc=gocomplete#Complete
autocmd vimrc FileType typescript
  \ setlocal omnifunc=TSScompleteFunc

" cancel or accept
imap <silent> <expr> <C-c> pumvisible() ? "\<C-r>=neocomplete#cancel_popup()\<CR>" : "\<Esc>"
imap <silent> <expr> <C-j> pumvisible() ? "\<C-r>=neocomplete#close_popup()\<CR>" : "\<CR>"
