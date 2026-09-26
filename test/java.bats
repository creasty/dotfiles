#!/usr/bin/env bats
#
# lang.mise.java: Homebrew's JDKs, selected by mise from config/mise/config.toml or .java-version

load helper

# bats file_tags=lang:mise:java

jdk_home() {
  echo "$HOMEBREW_PREFIX/opt/openjdk@$1/libexec/openjdk.jdk/Contents/Home"
}

@test "the JDKs and JVM tools are installed" {
  # shellcheck disable=SC2046
  assert_formulae $(config '.java.versions[]') $(role_formulae java)
}

@test "macOS finds the default JDK" {
  assert_same_file /Library/Java/JavaVirtualMachines/openjdk.jdk \
    "$HOMEBREW_PREFIX/opt/$(config '.java.versions[0]')/libexec/openjdk.jdk"
  run -0 /usr/libexec/java_home -V
  assert_like "$output" '*/Library/Java/JavaVirtualMachines/openjdk.jdk/Contents/Home*'
}

@test "terminals use the configured JDK" {
  require_linked .profile .zshenv .zshrc .config/mise
  local version
  version="$(mise_config '.tools.java')"
  run -0 login_zsh 'print -r -- $JAVA_HOME; java -version 2>&1'
  assert_same_file "${lines[0]}" "$(jdk_home "$version")"
  assert_like "${lines[1]}" "* \"$version.*"
}

@test "a .java-version file switches the JDK when changing directories" {
  require_linked .profile .zshenv .zshrc .config/mise
  local formula version
  for formula in $(config '.java.versions[]'); do
    version="${formula#openjdk@}"
    mkdir "$BATS_TEST_TMPDIR/$version"
    echo "$version" > "$BATS_TEST_TMPDIR/$version/.java-version"

    run -0 login_zsh "cd $(q "$BATS_TEST_TMPDIR/$version") && print -r -- \$JAVA_HOME && java -version 2>&1"
    assert_same_file "${lines[0]}" "$(jdk_home "$version")"
    assert_like "${lines[1]}" "* \"$version.*"
  done
}

@test "java runs a program" {
  require_linked .profile .zshenv .zshrc .config/mise
  cd "$BATS_TEST_TMPDIR"
  echo 'class Hello { public static void main(String[] args) { System.out.println("hello"); } }' > Hello.java
  run -0 login_zsh 'java Hello.java'
  assert_equal "$output" hello
}
