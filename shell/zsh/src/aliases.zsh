#  General
#-----------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias 1='cd -'
alias 2='cd -2'
alias 3='cd -3'

alias ls='exa'
alias ll='exa -l'
alias la='exa -a'
alias lla='exa -la'
alias tree='exa --tree'
alias df='df -h'
alias tf='tail -f'
alias less='less -R'

alias sort='LC_ALL=C sort'
alias path='echo -e ${PATH//:/\\n}'
alias vim='nvim'
alias vi='nvim'
alias :q='exit'

#  Global
#-----------------------------------------------
alias -g A='| awk'
alias -g C='| cat'
alias -g D='| sed'
alias -g G='| rg'
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
alias -g XL='| tr "\n" "\0" | xargs -0'
alias -g P='| peco'

#  Bin
#-----------------------------------------------
alias x86='arch -x86_64'

alias pbc='pbcopy'
alias pbp='pbpaste'
alias sha1='openssl sha1 | sed "s/^.* //"'
alias uuidgen="uuidgen | tr 'A-F' 'a-f'"

# ssh-keygen [-q] [-b bits] [-t dsa | ecdsa | ed25519 | rsa] [-N new_passphrase] [-C comment] [-f output_keyfile]
alias skey='ssh-keygen -q -t ed25519 -C "yuki@creasty.com" -f'
alias skey-rsa='ssh-keygen -q -b 4096 -t rsa -N "" -C "yuki@creasty.com" -f'

alias g='envchain crst git'

rg() {
  command rg -p -M 1000 "$@" | less -R
}

alias o='finder'
alias ev='envchain'
alias gk='grep-kill'

alias va='vagrant'
alias an='ansible'
alias anp='ansible-playbook'
alias anv='ansible-vault'
alias ql='qlmanage -p "$@" >& /dev/null'

alias ptex2pdf='texlive ptex2pdf -ot "-interaction=nonstopmode -file-line-error-style -shell-escape" -od "-d 5" -l'

ssh() {
  cat ~/.ssh/config.d/* > ~/.ssh/config
  [ $# -gt 0 ] && command ssh "$@"
}

#  Networks
#-----------------------------------------------
alias hosts='vi /etc/hosts'
alias ip='ipconfig getifaddr en0 || ipconfig getifaddr en1'
alias ipg='dig +short myip.opendns.com @resolver1.opendns.com'
alias flush-dns='sudo killall -HUP mDNSResponder'
alias sniff="sudo ngrep -d 'en0' -t '^(GET|POST) ' 'tcp and port 80'"

for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
  alias "$method"="curl -X '$method'"
done

ipf() {
  curl -H 'Accept: application/json' "ipinfo.io/$1" | jq .
}

digga() {
  dig +nocmd "$1" any +multiline +noall +answer
}

#  Docker
#-----------------------------------------------
alias dk='docker'
alias dkc='docker-compose'
alias dkm='docker-machine'

alias dk-ips="docker ps -q | xargs -n 1 docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} {{ .Name }}' | sed 's/ \//\t/'"
alias dk-clean='docker-clean'

#  Google Cloud SDK
#-----------------------------------------------
# alias gcloud='google-cloud-sdk gcloud'
# alias gsutil='google-cloud-sdk gsutil'
# alias bq='google-cloud-sdk bq'
# alias kubectl='google-cloud-sdk kubectl'

alias ku='kubectl'
alias ku-oneshot='kubectl-oneshot'

#  Ruby / Rails
#-----------------------------------------------
alias b='bundle'
alias be='bundle exec'
alias bi='bundle install --path=vendor/bundle --binstubs=vendor/bundle/bin'

alias ra='bundle exec rails'
alias rkr='bundle exec rails routes'
alias rc='bundle exec rails c'
alias rs='bundle exec rails s -b 0.0.0.0'
alias rs1='bundle exec rails s -b 0.0.0.0 -p 3001'
alias rs2='bundle exec rails s -b 0.0.0.0 -p 3002'
alias rs3='bundle exec rails s -b 0.0.0.0 -p 3003'
alias rs4='bundle exec rails s -b 0.0.0.0 -p 3004'
alias rs5='bundle exec rails s -b 0.0.0.0 -p 3005'

alias rk='bundle exec rake'
alias rdbc='bundle exec rake db:create'
alias rdbr='bundle exec rake db:reset'
alias rdbs='bundle exec rake db:setup'
alias rdbm='rake-db-migrate'
alias rdba='rake-db-migrate-all'

rbserver() {
  ruby -rwebrick -e 'WEBrick::HTTPServer.new(DocumentRoot: ".", BindAddress: "0.0.0.0", Port: (ARGV[0] || 5000).to_i).start' "$@"
}

#  Rust
#-----------------------------------------------
alias ca='cargo'
alias cab='cargo build'
alias cau='cargo update'
alias car='cargo run'
alias cac='cargo check'

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

#  Gradle
#-----------------------------------------------
alias gr='./gradlew'
alias grb='./gradlew build'
alias grr='./gradlew run'

#  Henry
#-----------------------------------------------
hen-proxy-db() {
  local repo="$(ghq root)/github.com/bw-company/henry-infra"
  "$repo/script/proxy-database" "$@"
}
