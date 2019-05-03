function! vimrc#plugin#altr#lazy_init() abort
  " Header files
  call altr#define('%.c', '%.h', '%.m')

  " Rails / Ruby
  call altr#define('app/models/%.rb', 'spec/models/%_spec.rb', 'spec/factories/%s.rb')
  call altr#define('app/%/%.rb', 'spec/%/%_spec.rb')
  call altr#define('lib/%.rb', 'spec/lib/%_spec.rb')
  call altr#define('%.html.haml', '%_smart_phone.html.haml')
  call altr#define('%.html.slim', '%_smart_phone.html.slim')
  call altr#define('Gemfile', 'Gemfile.lock')

  " I18n
  let l:locales = ['en', 'ja', 'zh-HK', 'de']
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

  " Frontend
  call altr#define('src/%.coffee', 'spec/%_spec.coffee', 'test/%_spec.coffee', 'test/%.coffee')
  call altr#define('%.js', '%.jsx', '%.coffee', '%.scss', '%.jade', '%.ace')

  " Golang
  call altr#define('%.go', '%_test.go', '%_mock.go', '%_ex_test.go')
  call altr#define('glide.yaml', 'glide.lock')
  call altr#define('Gopkg.toml', 'Gopkg.lock')
  call altr#define('default.yml', 'development.yml', 'qa.yml', 'production.yml')
  call altr#define('%.dowm.sql', '%.up.sql')

  " Docker
  call altr#define('docker-compose.yml', 'Dockerfile')
  call altr#define('script/ci-build', 'script/ci-deploy', '.travis.yml')

  " Dotenv
  call altr#define('.env', '.env.sample')

  " Vim
  call altr#define('dein.toml', 'dein_lazy.toml')
endfunction
