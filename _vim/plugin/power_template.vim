if exists('g:loaded_power_template') || v:version < 702
  finish
endif
let g:loaded_power_template = 1

let s:save_cpo = &cpo
set cpo&vim


let g:power_template_dir = get(g:, 'power_template_dir', '~/.vim/template')

command! -nargs=? -bar -complete=customlist,power_template#complete
  \ Template call power_template#load(<q-args>, <line1>)



"=== Template
"==============================================================================================
" let g:template_basedir = s:env.path.template
"
" function! s:template_loaded()
"   %s/<+FILE_PATH+>/\=expand('%:p')/ge
"   %s/<+FILE_NAME+>/\=expand('%:t')/ge
"
"   silent! :%!erb
"
"   if search('<+CURSOR+>')
"     execute 'normal! "_da>'
"   endif
" endfunction
"
" autocmd User plugin-template-loaded call <SID>template_loaded()

let &cpo = s:save_cpo
unlet s:save_cpo
