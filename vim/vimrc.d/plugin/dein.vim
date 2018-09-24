command! PrunePlugins
  \ call map(dein#check_clean(), "delete(v:val, 'rf')") |
  \ call dein#recache_runtimepath() |
  \ echo 'done'
