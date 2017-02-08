#  General
#-----------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias 1='cd -'
alias 2='cd -2'
alias 3='cd -3'

alias ls='ls -G'
alias ll='ls -Gl'
alias la='ls -Ga'
alias lla='ls -Gla'
alias tree='tree -C'
alias df='df -h'
alias tf='tail -f'
alias less='less -R'
alias le='less -R'

alias v='vim'
alias vi='vim'
alias vv='mvim'

alias sort='LC_ALL=C sort'

alias :q='exit'


#  Global
#-----------------------------------------------
alias -g A='| awk'
alias -g C='| cat'
alias -g D='| sed'
alias -g G='| ag'
alias -g H='| head'
alias -g J='| jq .'
alias -g JL='| jq -C . | less'
alias -g L='| less'
alias -g N='> /dev/null'
alias -g NN='> /dev/null 2>&1'
alias -g S='| sort'
alias -g W='| wc'
alias -g WL='| wc -l'
alias -g X='| xargs'
alias -g X1='| xargs -n 1'
alias -g P='| peco'


#  Suffix
#-----------------------------------------------
alias -s coffee='coffee'
alias -s go='go run'
alias -s hs='runhaskell'
alias -s js='node'
alias -s php='php -f'
alias -s py='python'
alias -s rb='ruby'
alias -s swift='xcrun swift'
alias -s txt='cat'

alias -s {gif,jpg,jpeg,png,bmp}='display'

_run_c() {
  local file="$1"
  local out="${1/\.c/}"
  shift

  gcc -o $out $file && $out $@
  rm -f $out
}
alias -s c='_run_c'

_run_java() {
  className=$1
  className=${className%.java}
  javac $1
  shift
  java $className $@
}
alias -s java='_run_java'


#  Bin
#-----------------------------------------------
alias g='envchain crst git'
alias ag="ag --pager='less -R'"

alias pbc='pbcopy'
alias pbp='pbpaste'
alias sha1='echo -n "${1}" | openssl sha1 | sed "s/^.* //"'
alias skey='ssh-keygen -q -b 2048 -t rsa -N "" -C "" -f'

alias o='finder'
alias c='see'
alias ev='envchain-enhanced'
alias ne='npm-exec'
alias gk='grep-kill'
alias rdba='rake-db-migrate-all'

alias va='vagrant'
alias an='ansible'
alias anp='ansible-playbook'
alias anv='ansible-vault'
alias gl='glide'
alias tex2pdf='ptex2pdf -l'
alias ql='qlmanage -p "$@" >& /dev/null'
alias mas='reattach-to-user-namespace mas'
alias :save="$TMUX_RESURRECT_SCRIPTS_PATH/save.sh"
alias :restore="$TMUX_RESURRECT_SCRIPTS_PATH/restore.sh"
alias maxscreen='screenresolution set 2560x1600x32@0'  # screenresolution list

erd() {
  local cmd=$HOME/.cabal/bin/erd
  $cmd -i "$1" -o "${1/.er/}.${2:-png}"
}

compdef g='git'
compdef va='vagrant'
compdef an='ansible'
compdef anp='ansible-playbook'
compdef anv='ansible-vault'


#  Networks
#-----------------------------------------------
alias hosts='vi /etc/hosts'
alias ip='ipconfig getifaddr en0 || ipconfig getifaddr en1'
alias ipg='dig +short myip.opendns.com @resolver1.opendns.com'
alias whois='whois -h whois-servers.net'
alias flush-dns='sudo killall -HUP mDNSResponder'
alias sniff="sudo ngrep -d 'en0' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en0 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

ipf() {
  curl "ipinfo.io/$1" | jq .
}


#  Servers
#-----------------------------------------------
alias redis-server='redis-server /usr/local/etc/redis.conf'
alias pg-server='pg_ctl -D /usr/local/var/postgres start -l /dev/null'

rbserver() {
  local port=${1:-5000}
  ruby -rwebrick -e "WEBrick::HTTPServer.new(DocumentRoot: './', Port: $port).start"
}


#  Docker
#-----------------------------------------------
alias dk='docker'
alias dkc='docker-compose'
alias dkm='docker-machine'

dk-clean() {
  docker rmi $(docker images -f "dangling=true" -q)
}

dk-open() {
  open "http://$(docker-machine ip local)$@"
}

#  Ruby / Rails
#-----------------------------------------------
alias b='bundle'
alias be='bundle exec'
alias bi='bundle install --path=vendor/bundle --binstubs=vendor/bundle/bin'

alias ra='bundle exec rails'
alias rg='bundle exec rails g'
alias rgmo='bundle exec rails g model'
alias rgmi='bundle exec rails g migration'

alias rk='bundle exec rake'
alias rkr='bundle exec rake routes'

alias rdbc='bundle exec rake db:create'
alias rdbm='bundle exec rake db:migrate'
alias rdbr='bundle exec rake db:reset'
alias rdbs='bundle exec rake db:setup'
alias rdbf='bundle exec rake db:migrate:reset && bundle exec rake db:seed'

rdbb() {
  bundle exec rake db:rollback STEP=$1
}
rdbd() {
  bundle exec rake db:migrate:down VERSION=$1
}

alias rc='bundle exec rails c'
alias rs='bundle exec rails s'
alias rs1='bundle exec rails s -p 3001'
alias rs2='bundle exec rails s -p 3002'
alias rs3='bundle exec rails s -p 3003'
alias rs4='bundle exec rails s -p 3004'
alias rs5='bundle exec rails s -p 3005'

compdef b='bundle'
compdef rk='rake'


#  Play framework
#-----------------------------------------------
alias act='activator'
alias actr='activator run'
alias actt='activator test'


#  Make
#-----------------------------------------------
alias gmake='make'

alias m='make'
alias mi='make install'
alias mc='make clean'


#  tmux
#-----------------------------------------------
alias tm='tmux'
alias tma='tmux attach'
alias tma0='tmux attach -t 0'
alias tma1='tmux attach -t 1'
alias tma2='tmux attach -t 2'
alias tml='tmux list-sessions'


#  Xcode
#-----------------------------------------------
# xcodebuild test -scheme foo -destination 'platform=iOS Simulator,name=iPad' | xcpretty -c
# xctool -scheme foo run-tests -parallelize -sdk iphonesimulator

alias swift='xcrun swift'
alias swiftc='SDKPATH=$(/usr/bin/env xcrun --show-sdk-path --sdk macosx) xcrun swiftc'

alias xcb='xcodebuild'
alias xct='xctool'
