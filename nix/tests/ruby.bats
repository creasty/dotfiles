#!/usr/bin/env bats
#
# Ruby at the version of config/mise/config.toml, built against Homebrew's libraries

load helper

setup() {
  ruby_version="$(mise_config '.tools.ruby')"
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

@test "ruby is built with OpenSSL, libyaml, zlib and GMP" {
  # macOS has no OpenSSL 3, libyaml or GMP of its own: loading these proves Homebrew's were built in
  run -0 login_bash 'ruby -ropenssl -rpsych -rzlib -e "puts OpenSSL::OPENSSL_LIBRARY_VERSION, Psych::LIBYAML_VERSION, Integer::GMP_VERSION"'
  assert_like "${lines[0]}" 'OpenSSL 3.*'
  assert_like "${lines[2]}" 'GMP *'
}

# Homebrew removes a library installed as another formula's dependency along with that formula, and ruby then fails
# to start. ruby-build builds against some that it finds installed (e.g. gmp).
@test "ruby links only the Homebrew formulae that provisioning installs" {
  local prefix="$HOME/.local/share/mise/installs/ruby/$ruby_version" brews formula problems=''
  brews="$(manifest '.homebrew.brews[]' | sed 's|.*/||')"
  # The ruby command and the libraries and extensions that come with it, not those of gems
  for formula in $(
    find "$prefix/bin/ruby" "$prefix/lib" -path "$prefix/lib/ruby/gems" -prune -o \
      -type f \( -name ruby -o -name '*.dylib' -o -name '*.bundle' \) -print0 |
      xargs -0 otool -L | grep -oE '/opt/homebrew/opt/[^/]+' | sort -u
  ); do
    grep -qxF -- "${formula##*/}" <<< "$brews" || problems+="${formula##*/}"$'\n'
  done
  assert_none "$problems" 'linked, but not installed by provisioning'
}

# Apart from Ruby, as a project's .ruby-version swaps the Ruby that runs
@test "terminals run the gem tools from their own installs" {
  local version
  version="$(mise_config '.tools["gem:solargraph"]')"
  run -0 login_zsh 'print -r -- $commands[solargraph]; solargraph --version'
  assert_equal "${lines[0]}" "$HOME/.local/share/mise/installs/gem-solargraph/$version/bin/solargraph"
  assert_equal "${lines[1]}" "$version"
}
