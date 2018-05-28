function! s:altr_on_source() abort
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
  call altr#define('locales/%/en.yml', 'locales/%/ja.yml', 'locales/%/zh-HK.yml')
  call altr#define('locales/%.en.yml', 'locales/%.ja.yml', 'locales/%.zh-HK.yml')
  call altr#define('locales/en.yml', 'locales/ja.yml', 'locales/zh-HK.yml')
  call altr#define('locales/en.json', 'locales/ja.json')
  call altr#define('locales/%/en.json', 'locales/%/ja.json')

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

nmap ga <Plug>(altr-forward)
nmap gA <Plug>(altr-back)

call dein#set_hook('vim-altr', 'hook_source', function('s:altr_on_source'))
