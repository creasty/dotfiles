let g:vim_tags_auto_generate = 1
let g:vim_tags_main_file = '.tags'
let g:vim_tags_gems_tags_command = '{CTAGS} -R {OPTIONS} `rbenv exec bundle show --paths` 2>/dev/null'

let g:vim_tags_directories = [
  \ '.git',
  \ '.hg',
  \ '.svn',
  \ '.vimprojectroot',
  \ '.bzr',
  \ '_darcs',
  \ 'CVS',
\ ]

nnoremap tg :TagsGenerate<CR>
