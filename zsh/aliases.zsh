#  General
#-----------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias ls='ls -G'
alias ll='ls -Gl'
alias la='ls -Ga'
alias lla='ls -Gla'
alias tree='tree -C'
alias df='df -h'
alias tf='tail -f'
alias less='less -R'

alias v='vim'
alias vi='vim'
alias vv='mvim'
alias g='envchain crst git'
alias ag="ag --pager='less -R'"

alias sort='LC_ALL=C sort'

alias :q='exit'

alias pbc='pbcopy'
alias pbp='pbpaste'

alias o='finder'

alias sha1='echo -n "${1}" | openssl sha1 | sed "s/^.* //"'

alias skey='ssh-keygen -q -b 2048 -t rsa -N "" -C "" -f'
alias randportn='ruby -e "p rand(1024..65535)"'
alias randports='ruby -e "p rand(49152..65535)"'


#  Global
#-----------------------------------------------
alias -g A='| awk'
alias -g C='| cat'
alias -g D='| sed'
alias -g E='> /dev/null 2>&1'
alias -g G='| grep'
alias -g H='| head'
alias -g L='| less'
alias -g N='> /dev/null'
alias -g S='| sort'
alias -g W='| wc'
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


#  Applications
#-----------------------------------------------
alias va='vagrant'
alias an='ansible'
alias anp='ansible-playbook'
alias tex2pdf='ptex2pdf -l'
alias enx='evernote-sandbox'
alias ne='npm-exec'
alias ql='qlmanage -p "$@" >& /dev/null'
alias gk='grep-kill'

alias maxscreen='screenresolution set 2560x1600x32@0'

erd() {
  local cmd=$HOME/.cabal/bin/erd
  $cmd -i "$1" -o "${1}.${2:-png}"
}

TMUX_RESURRECT_SCRIPTS_PATH=~/.tmux/plugins/tmux-resurrect/scripts
alias :save="$TMUX_RESURRECT_SCRIPTS_PATH/save.sh"
alias :restore="$TMUX_RESURRECT_SCRIPTS_PATH/restore.sh"



#  Networks
#-----------------------------------------------
alias hosts='vi /etc/hosts'
alias ip='ipconfig getifaddr en0 || ipconfig getifaddr en1'
alias ipg='dig +short myip.opendns.com @resolver1.opendns.com'
alias whois='whois -h whois-servers.net'

alias sniff="sudo ngrep -d 'en0' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en0 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""


#  Servers
#-----------------------------------------------
alias pyserver="python -m SimpleHTTPServer"
alias nserver="http-server -p"

rbserver() {
  local port=${1:-5000}
  ruby -rwebrick -e "WEBrick::HTTPServer.new(DocumentRoot: './', Port: $port).start"
}

alias redis-server='redis-server /usr/local/etc/redis.conf'
alias pg-server='postgres -D /usr/local/var/postgres > /dev/null 2>&1 &'

alias es='elasticsearch -Xms1g -Xmx2g -Des.script.disable_dynamic=false'


#  Scripts
#-----------------------------------------------
alias aart='java -jar ~/dotfiles/lib/jitac.jar'

alias webkit2png='webkit2png -F -d -D ~/Desktop/'
alias webkit2evernote='webkit2png -C -W 1920 -H 1200 --clipwidth=960 --clipheight=600 -s 0.5 -D ~/Desktop/ -d'
alias webkit2blog='webkit2png -C -W 1474 -H 696 --clipwidth=737 --clipheight=348 -s 0.5 -D ~/Desktop/ -d'


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

alias rdba='rake-db-migrate-all'

rdbb() {
  bundle exec rake db:rollback STEP=$1
}

alias rc='bundle exec rails c'
alias rs='bundle exec rails s'
alias rs1='bundle exec rails s -p 3001'
alias rs2='bundle exec rails s -p 3002'
alias rs3='bundle exec rails s -p 3003'
alias rs4='bundle exec rails s -p 3004'
alias rs5='bundle exec rails s -p 3005'


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
