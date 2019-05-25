setlocal path+=$GOPATH/src,/usr/local/opt/go/libexec/src
setlocal suffixesadd=.go,/
setlocal include=^\\t\\%(\\w\\+\\s\\+\\)\\=\"\\zs[^\"]*\\ze\"$
