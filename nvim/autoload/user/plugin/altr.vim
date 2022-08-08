function! user#plugin#altr#lazy_init() abort
  " Header files
  call altr#define('%.c', '%.h', '%.m')

  " Rails / Ruby
  call altr#define('app/models/%.rb', 'spec/models/%_spec.rb', 'spec/factories/%s.rb')
  call altr#define('app/%/%.rb', 'spec/%/%_spec.rb')
  call altr#define('lib/%.rb', 'spec/lib/%_spec.rb')
  call altr#define('Gemfile', 'Gemfile.lock')

  " Frontend
  call altr#define('%.js', '%.test.js')
  call altr#define('%.ts', '%.test.ts')
  call altr#define('%.tsx', '%.test.tsx')

  " Golang
  call altr#define('%.go', '%_test.go', '%_mock.go', '%_ex_test.go')
  call altr#define('go.mod', 'go.sum')

  " Docker
  call altr#define('docker-compose.yml', 'Dockerfile')

  " Vim
  call altr#define('dein/default.toml', 'dein/lazy.toml')

  " Config
  call altr#define('.env', '.env.sample', '.env.local', '.env.development', '.env.test')
  call altr#define('.env.%', '.env.%.local')
  call altr#define('default.properties', 'local.properties', 'test.properties')
  call altr#define('%.properties', '%.local.properties')

  " TLA+
  call altr#define('%.tla', '%.cfg')

  " I18n
  let l:locales = ['en', 'ja']
  let l:localized_files = [
    \ 'locales/@.yml',
    \ 'locales/%.@.yml',
    \ 'locales/%/@.yml',
    \ 'locales/@.json',
    \ 'locales/%.@.json',
    \ 'locales/%/@.json',
  \ ]
  for l:file in l:localized_files
    let l:files = map(copy(l:locales), { i, locale -> substitute(l:file, '@', l:locale, 'g') })
    call call('altr#define', l:files)
  endfor
endfunction
