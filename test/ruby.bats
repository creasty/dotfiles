#!/usr/bin/env bats
#
# Ruby at the version of config/mise/config.toml, built against Homebrew's libraries

load helper

setup() {
  ruby_version="$(mise_config '.tools.ruby.version')"
}

@test "terminals run ruby from mise at the configured version" {
  run -0 login_zsh 'print -r -- $commands[ruby]; ruby -e "print RUBY_VERSION"'
  assert_equal "${lines[0]}" "$HOME/.local/share/mise/installs/ruby/$ruby_version/bin/ruby"
  assert_equal "${lines[1]}" "$ruby_version"
}

@test "scripts and login bash run gems through mise's shims" {
  run -0 login_bash 'command -v gem'
  assert_equal "$output" "$HOME/.local/share/mise/shims/gem"
}

@test "ruby is built with OpenSSL, libyaml and zlib" {
  # macOS has no OpenSSL 3 or libyaml of its own: loading these proves Homebrew's were built in
  run -0 login_bash 'ruby -ropenssl -rpsych -rzlib -e "puts OpenSSL::OPENSSL_LIBRARY_VERSION, Psych::LIBYAML_VERSION"'
  assert_like "${lines[0]}" 'OpenSSL 3.*'
}

@test "default gems are installed" {
  local gem problems=''
  run -0 login_bash 'gem list --no-versions'
  # shellcheck disable=SC2013
  for gem in $(sed 's/#.*//' "$DOTFILES_PATH/config/mise/default-gems"); do
    grep -qxF -- "$gem" <<< "$output" || problems+="$gem"$'\n'
  done
  assert_none "$problems" 'not installed'
}
