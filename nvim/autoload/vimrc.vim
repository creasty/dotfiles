function! s:get_env() abort
  let l:env = {}

  let l:dotfiles_path = $DOTFILES_PATH
  if empty(l:dotfiles_path)
    let l:dotfiles_path = $HOME . '/dotfiles'
  endif

  let l:vim_path = l:dotfiles_path . '/nvim'

  let l:env.path = {
    \ 'dotfiles':       l:dotfiles_path,
    \ 'dein':           l:vim_path . '/dein',
    \ 'dein_repo':      l:vim_path . '/dein/repos/github.com/Shougo/dein.vim',
    \ 'dein_toml':      l:vim_path . '/dein.toml',
    \ 'dein_lazy_toml': l:vim_path . '/dein_lazy.toml',
  \ }

  return l:env
endfunction

let g:vimrc#env = s:get_env()
