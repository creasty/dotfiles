#!/usr/bin/env bats
#
# Homebrew's JDKs, selected by mise from config/mise/config.toml or .java-version (nix/modules/java.nix)

load helper

jdk_home() {
  echo "$HOMEBREW_PREFIX/opt/openjdk@$1/libexec/openjdk.jdk/Contents/Home"
}

@test "the JDKs are installed" {
  # shellcheck disable=SC2046
  assert_formulae $(manifest '.java.versions[] | "openjdk@" + .')
}

@test "macOS finds the default JDK" {
  local jdk
  jdk="$HOMEBREW_PREFIX/opt/openjdk@$(manifest '.java.versions[0]')/libexec/openjdk.jdk"
  assert_same_file /Library/Java/JavaVirtualMachines/openjdk.jdk "$jdk"
  # java_home lists the JDKs by their resolved path
  run -0 /usr/libexec/java_home -V
  assert_like "$output" "* $(cd "$jdk/Contents/Home" && pwd -P)*"
}

@test "terminals use the configured JDK" {
  local version
  version="$(mise_config '.tools.java')"
  run -0 login_zsh 'print -r -- $JAVA_HOME; java -version 2>&1'
  assert_same_file "${lines[0]}" "$(jdk_home "$version")"
  assert_like "${lines[1]}" "* \"$version.*"
}

@test "a .java-version file switches the JDK when changing directories" {
  local version
  for version in $(manifest '.java.versions[]'); do
    mkdir "$BATS_TEST_TMPDIR/$version"
    echo "$version" > "$BATS_TEST_TMPDIR/$version/.java-version"

    run -0 login_zsh "cd $(q "$BATS_TEST_TMPDIR/$version") && print -r -- \$JAVA_HOME && java -version 2>&1"
    assert_same_file "${lines[0]}" "$(jdk_home "$version")"
    assert_like "${lines[1]}" "* \"$version.*"
  done
}

@test "java runs a program" {
  cd "$BATS_TEST_TMPDIR"
  echo 'class Hello { public static void main(String[] args) { System.out.println("hello"); } }' > Hello.java
  run -0 login_zsh 'java Hello.java'
  assert_equal "$output" hello
}
