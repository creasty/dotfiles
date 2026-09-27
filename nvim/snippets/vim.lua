-- Converted from UltiSnips' vim.snippets
local S = require('user.snippets')

-- `plugin/foo-bar.vim` -> `foo_bar_vim`
local function guard_var()
  return { GUARD = (vim.fn.expand('%:t'):gsub('[^%w_]+', '_'):lower()) }
end

return {
  S.snip('augroup', 'augroup', 'b', [[
augroup ${1:name}
	autocmd!
	autocmd $0
augroup END]]),
  S.snip('cpo', 'cpo guard', 'b', [[
let s:save_cpo = &cpo
set cpo&vim

$0

let &cpo = s:save_cpo
unlet s:save_cpo]]),
  S.snip('func', 'Create Function', 'b', [[
function! ${1:name}() abort
	$0
endfunction]]),
  S.snip('guard', 'Load guard', 'b', [[
if exists('g:loaded_${1:$GUARD}')
	finish
endif

let g:loaded_$1 = 1
]], { vars = guard_var }),
  S.snip('redir', 'redir ... END', 'b', [[
redir => ${1:var_name}
	$0
redir END]]),
  S.snip([["\@<!"]], 'Heading 1', 'br', '"=== $0\n"' .. ('='):rep(94)),
  S.snip([["\@<!""]], 'Heading 2', 'br', '"  $0\n"' .. ('-'):rep(47)),
  S.snip('minimum_rtp', 'Build rtp for minimum init.vim', 'b', [[
if has('vim_starting')
	let s:repos = [
		\ '$0',
	\ ]

	let s:config_path = stdpath('config')
	let s:paths = filter(split(&g:rtp, ','), { _, v -> v !=# s:config_path && v !=# s:config_path . '/after' })
	let s:paths += map(s:repos, { _, v -> stdpath('data') . '/lazy/' . v })
	let &g:rtp = join(s:paths, ',')
endif]]),
}
