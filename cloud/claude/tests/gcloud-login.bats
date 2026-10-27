#!/usr/bin/env bats
#
# ../skills/gcloud-login/scripts/gcloud-login.sh, with the Google Cloud CLI up to a login, which needs a person at
# Google's page, and with a fake of it (fakes/gcloud) for what follows one

bats_require_minimum_version 1.7.0
bats_load_library bats-support
bats_load_library bats-assert

setup() {
  script="$BATS_TEST_DIRNAME/../skills/gcloud-login/scripts/gcloud-login.sh"
  export HOME="$BATS_TEST_TMPDIR/home" TMPDIR="$BATS_TEST_TMPDIR/tmp" CLOUDSDK_CONFIG="$BATS_TEST_TMPDIR/gcloud"
  mkdir -p "$HOME" "$TMPDIR"
  unset CLOUDSDK_AUTH_ACCESS_TOKEN
}

# Stops a login left waiting for its code: its gcloud runs in a session of its own, whose leader's PID the script
# keeps in its state directory (timeout puts gcloud in a process group of its own, within that session)
teardown() {
  local pid
  pid="$(cat "$TMPDIR/gcloud-login-$(id -u)/pid" 2> /dev/null)" || return 0
  pkill -s "$pid" || true
}

fake_gcloud() {
  export PATH="$BATS_TEST_DIRNAME/fakes:$PATH"
}

#  With the Google Cloud CLI
#-----------------------------------------------
@test "status shows no account and no ADC before a login" {
  run -0 "$script" status
  assert_equal "$output" "gcloud CLI's account: (none)"$'\n'"ADC: invalid"
}

@test "start prints Google's login URL, which PKCE binds to the login" {
  run -0 "$script" start
  assert_line --index 1 --regexp '^https://accounts\.google\.com/'
  assert_line --index 1 --partial code_challenge=
  assert_line --index 1 --partial code_challenge_method=S256
}

@test "start again, while the login waits, prints the same URL" {
  run -0 "$script" start
  local url="${lines[1]}"
  run -0 "$script" start
  assert_line --index 0 --partial 'A login is already running.'
  assert_equal "${lines[1]}" "$url"
}

@test "finish with a wrong code fails with gcloud's output, and logs nothing in" {
  run -0 "$script" start
  run -1 "$script" finish wrong-code
  assert_equal "${lines[0]}" "The login failed. gcloud's output:"
  assert_output --partial 'ERROR: (gcloud.auth.login)'
  run -0 "$script" status
  assert_equal "${lines[0]}" "gcloud CLI's account: (none)"
}

@test "finish without a login running fails" {
  run -1 "$script" finish good-code
  assert_output --partial 'No login is running'
}

@test "revoke with nothing logged in leaves nothing" {
  run -0 "$script" revoke
  assert_equal "${lines[-1]}" 'No credentials of the gcloud CLI or ADC are left'
}

@test "with no command, it prints its usage" {
  run -1 "$script"
  assert_line --index 0 --partial 'Logs gcloud in'
  assert_line --index -1 --partial 'gcloud-login.sh revoke'
}

#  With the fake, after a login
#-----------------------------------------------
@test "finish hands gcloud the code, and ends logged in with ADC" {
  fake_gcloud
  run -0 "$script" start
  run -0 "$script" finish good-code
  assert_equal "$output" "gcloud CLI's account: user@example.com"$'\n'"ADC: valid"
}

@test "no gcloud call gets the placeholder token, which status reports" {
  fake_gcloud
  export CLOUDSDK_AUTH_ACCESS_TOKEN=proxy-injected
  run -0 "$script" start
  run -0 "$script" finish good-code
  assert_equal "${lines[0]}" "gcloud CLI's account: user@example.com"
  assert_line --index 2 --partial 'CLOUDSDK_AUTH_ACCESS_TOKEN is set:'
  run -0 "$script" revoke
  run -1 grep '^placeholder:' "$CLOUDSDK_CONFIG/calls"
}

@test "revoke revokes ADC before the CLI's credentials, and leaves neither" {
  fake_gcloud
  run -0 "$script" start
  run -0 "$script" finish good-code
  run -0 "$script" revoke
  assert_equal "${lines[-1]}" 'No credentials of the gcloud CLI or ADC are left'
  diff <(grep revoke "$CLOUDSDK_CONFIG/calls") - <<< $'auth application-default revoke --quiet\nauth revoke --all --quiet'
}

@test "revoke fails when credentials are left" {
  fake_gcloud
  export FAKE_GCLOUD_KEEP_ADC=1
  run -0 "$script" start
  run -0 "$script" finish good-code
  run -1 "$script" revoke
  assert_equal "${lines[-1]}" "Left unrevoked: ADC's file $CLOUDSDK_CONFIG/application_default_credentials.json"
}
