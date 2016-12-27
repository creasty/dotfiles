brew {
  casks = [
    "adobe-creative-cloud",
    "alfred",
    "android-studio",
    "dockertoolbox",
    "dropbox",
    "firefox",
    "flip4mac",
    "flux",
    "google-chrome",
    "google-hangouts",
    "google-japanese-ime",
    "growlnotify",
    "iterm2",
    "java7",
    "karabiner",
    "ngrok",
    "qlcolorcode",
    "qlmarkdown",
    "qlstephen",
    "quicklook-json",
    "sequel-pro",
    "skype",
    "sophos-antivirus-home-edition",
    "vagrant",
    "vault",
    "virtualbox",
    "webpquicklook",
    "xquartz",
  ]

  taps = [
    "creasty/homebrew-creasty",
    "homebrew/boneyard",
    "homebrew/dupes",
    "homebrew/science",
    "josegonzalez/php",
    "neovim/neovim",
    "supermomonga/homebrew-splhack",
  ]

  packages = [
    "android-sdk",
    "argon/mas/mas",
    "awscli --HEAD",
    "batik",
    "binutils",
    "cabal-install",
    "chisel",
    "clib",
    "clisp",
    "cloc",
    "ctags",
    "ctags-objc-ja --HEAD --enable-japanese-support",
    "curl --with-ssl --with-libssh2",
    "direnv",
    "elixir",
    "eot-utils",
    "fontconfig",
    "fontforge",
    "freetype",
    "fswatch",
    "gcutil",
    "gdb",
    "gdbm",
    "gettext",
    "ghc",
    "ghostscript",
    "git",
    "git-lfs",
    "gpg",
    "graphviz",
    "https://raw.githubusercontent.com/sorah/envchain/master/brew/envchain.rb",
    "imagemagick",
    "jbig2dec",
    "jo",
    "jpeg",
    "jq",
    "libepoxy",
    "libiconv",
    "libpcap",
    "libxml2",
    "libxslt",
    "lua",
    "luajit",
    "luarocks",
    "macvim --HEAD --with-luajit",
    "memcached",
    "mercurial",
    "mongodb",
    "mysql",
    "neovim --HEAD",
    "ngrep",
    "nkf",
    "opencv",
    "optipng",
    "osquery",
    "parallel",
    "pcre",
    "phantomjs",
    "php55",
    "plantuml",
    "postgresql",
    "pstree",
    "python3",
    "q",
    "r", // require xquartz to be installed",
    "ranger",
    "redis",
    "rsense",
    "ruby-build",
    "sbt",
    "scala",
    "sqlite",
    "terraform",
    "the_silver_searcher",
    "tig",
    "tmux",
    "tree",
    "typesafe-activator",
    "vim --HEAD --disable-nls --override-system-vi --with-luajit",
    "w3m",
    "webkit2png",
    "wget --enable-iri",
    "xctool",
    "zsh",
  ]
}

envchain "crst" {
  keys = [
    "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY",
    "GITHUB_ACCESS_TOKEN",
    "ATLAS_TOKEN",
  ]
}

envchain "wtd" {
  keys = [
    "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY",
    "REGISTRY_AWS_KEY",
    "REGISTRY_AWS_SECRET",
    "FACEBOOK_APP_ID",
    "FACEBOOK_APP_SECRET",
    "BASIC_AUTH_USERNAME",
    "BASIC_AUTH_PASSWORD",
    "AWS_REGION",
  ]
}

golang {
  versions = ["1.7"]

  packages = [
    "bitbucket.org/liamstask/goose/cmd/goose",
    "code.google.com/p/rog-go/exp/cmd/godef",
    "github.com/b4b4r07/gomi",
    "github.com/codegangsta/gin",
    "github.com/golang/lint/golint",
    "github.com/govend/govend",
    "github.com/laurent22/massren",
    "github.com/motemen/ghq",
    "github.com/nsf/gocode",
    "github.com/peco/peco/cmd/peco",
    "github.com/rakyll/boom",
    "github.com/tools/godep",
    "golang.org/x/tools/cmd/gotype",
    "github.com/Masterminds/glide",
  ]
}

haskell {
  packages = [
    "cabal-install",
    "erd",
    "pandoc",
  ]
}

lua {
  packages = [
    "md5",
    "stdlib",
    "lgi",
    "lpeg",
    "luaexpat",
    "inspect",
    "luaepnf",
    "luarepl",
    "cassowary",
  ]
}

nodejs {
  versions = ["7.2"]

  packages = [
    "coffee-script",
    "speed-test",
    "typescript-tools",
  ]
}

python {
  versions = ["2.7", "3"]

  packages = [
    "aws-shell --ignore-installed six",
    "awscli",
    "glances",
    "locustio",
    "misaka",
    "mitmproxy",
    "numpy",
    "pgcli",
    "protobuf",
    "pyamf",
    "pygments",
    "tornado",
  ]
}

r {
  packages = [
    "e1071",
    "ggplot2",
    "glmnet",
    "Hmisc",
    "igraph",
    "lme4",
    "lubridate",
    "plyr",
    "RCurl",
    "reshape",
    "RJSONIO",
    "scales",
    "tm",
    "XML",
  ]
}

ruby {
  versions = ["2.3"]

  rbenv_plugins = [
    "ianheggie/rbenv-binstubs",
    "sstephenson/rbenv-default-gems",
    "sstephenson/rbenv-gem-rehash",
  ]
}

vagrant {
  box "centos7" {
    image = "https://f0fff3908f081cb6461b407be80daf97f07ac418.googledrive.com/host/0BwtuV7VyVTSkUG1PM3pCeDJ4dVE/centos7.box"
  }

  plugins = [
    "sahara",
  ]
}
