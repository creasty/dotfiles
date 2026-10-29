#!/usr/bin/env bats
#
# ../skills/gcloud-login/scripts/gcloud-login.py, with the Google Cloud CLI and Google up to a login, which needs a
# person at Google's page, and with fakes of them (fakes/gcloud, fakes/google-oauth) for a login and what follows one

bats_require_minimum_version 1.7.0
bats_load_library bats-support
bats_load_library bats-assert

setup() {
  script="$BATS_TEST_DIRNAME/../skills/gcloud-login/scripts/gcloud-login.py"
  export HOME="$BATS_TEST_TMPDIR/home" CLOUDSDK_CONFIG="$BATS_TEST_TMPDIR/gcloud"
  mkdir -p "$HOME"
  unset CLOUDSDK_AUTH_ACCESS_TOKEN
}

teardown() {
  [ -z "${google:-}" ] || kill "$google"
}

# Serves the fake Google on a free port, which records its requests in $BATS_TEST_TMPDIR/requests
serve_google() {
  "$BATS_TEST_DIRNAME/fakes/google-oauth" "$BATS_TEST_TMPDIR/requests" > "$BATS_TEST_TMPDIR/port" 3>&- &
  google=$!
  for _ in $(seq 50); do
    [ -s "$BATS_TEST_TMPDIR/port" ] && break
    sleep 0.1
  done
  export FAKE_GOOGLE_OAUTH_URL="http://127.0.0.1:$(cat "$BATS_TEST_TMPDIR/port")"
}

# Has gcloud and Google be their fakes
fake_google() {
  export PATH="$BATS_TEST_DIRNAME/fakes:$PATH"
  serve_google
}

# Logs in at a login URL, as the user does in their browser, and prints the verification code the page shows
log_in_at() {
  curl -fsS "$1"
}

# Starts a login, and finishes it with the code of logging in at its URL
log_in() {
  run -0 "$script" start
  run -0 "$script" finish "$(log_in_at "${lines[1]}")"
}

# Logs in with gcloud's own login, which reads the code from its input once it has printed the URL
gcloud_log_in() {
  local pipe="$BATS_TEST_TMPDIR/code" log="$BATS_TEST_TMPDIR/gcloud-login.log" url=
  mkfifo "$pipe"
  # Held open for writing, the pipe lets gcloud open it, and gives it no EOF before the code
  exec 4<> "$pipe"
  gcloud auth login --no-launch-browser --update-adc < "$pipe" > "$log" 2>&1 3>&- 4>&- &
  local pid=$!
  for _ in $(seq 100); do
    url="$(grep -o "$CLOUDSDK_AUTH_AUTH_HOST[^[:space:]]*" "$log")" && break
    sleep 0.1
  done
  echo "$(log_in_at "$url")" >&4
  exec 4>&-
  wait "$pid" || { cat "$log"; return 1; }
}

# The fake Google's requests the jq condition selects, a JSON object a line, with their random values masked, and
# without the state gcloud adds to its URL, which the page that shows the code ignores
requests() {
  jq -cS "select($1) | .params |= (del(.state)
    | with_entries(if .key | IN(\"code\", \"code_verifier\", \"code_challenge\") then .value = \"(random)\" else . end))" \
    "$BATS_TEST_TMPDIR/requests"
}

# The credentials gcloud keeps in the configuration directory, a JSON object a line
credentials() {
  python3 -c '
import json, sqlite3, sys
for account, value in sqlite3.connect(sys.argv[1]).execute("select account_id, value from credentials"):
    print(json.dumps({"account": account, **json.loads(value)}, sort_keys=True))
' "$1/credentials.db"
}

#  With the Google Cloud CLI and Google
#-----------------------------------------------
@test "status shows no account and no ADC before a login" {
  run -0 "$script" status
  assert_equal "$output" "gcloud CLI's account: (none)"$'\n'"ADC: invalid"
}

@test "start again, while the login waits for its code, prints the same URL" {
  run -0 "$script" start
  local url="${lines[1]}"
  run -0 "$script" start
  assert_line --index 0 --partial 'A login is already waiting for its code.'
  assert_equal "${lines[1]}" "$url"
}

@test "finish with a wrong code fails with Google's error, and logs nothing in" {
  run -0 "$script" start
  run -1 "$script" finish wrong-code
  assert_line --index 0 --partial "Google didn't take the code: invalid_grant"
  run -0 "$script" status
  assert_equal "${lines[0]}" "gcloud CLI's account: (none)"
}

@test "gcloud's hidden activate-refresh-token, which finish hands the token, reads it from its input and checks it" {
  run -1 gcloud auth activate-refresh-token user@example.com <<< not-a-refresh-token
  assert_output --partial invalid_grant
  run -0 "$script" status
  assert_equal "${lines[0]}" "gcloud CLI's account: (none)"
}

@test "finish without a login waiting fails" {
  run -1 "$script" finish good-code
  assert_output --partial 'No login is waiting'
}

@test "revoke with nothing logged in leaves nothing" {
  run -0 "$script" revoke
  assert_equal "${lines[-1]}" 'No credentials of the gcloud CLI or ADC are left'
}

@test "with no command, it prints its usage" {
  run -1 "$script"
  assert_line --index 0 --partial 'Logs gcloud in'
  assert_line --index -1 --partial 'gcloud-login.py revoke'
}

#  With the Google Cloud CLI and the fake Google
#-----------------------------------------------
@test "a login asks Google what gcloud's own login asks, and leaves what it leaves" {
  serve_google
  # gcloud's endpoints and client are the fake's, which its OAuth library takes over plain HTTP
  export CLOUDSDK_AUTH_AUTH_HOST="$FAKE_GOOGLE_OAUTH_URL/auth" CLOUDSDK_AUTH_TOKEN_HOST="$FAKE_GOOGLE_OAUTH_URL/token" \
    CLOUDSDK_AUTH_CLIENT_ID=fake-client-id CLOUDSDK_AUTH_CLIENT_SECRET=fake-client-secret OAUTHLIB_INSECURE_TRANSPORT=1
  local own="$BATS_TEST_TMPDIR/own" ours="$BATS_TEST_TMPDIR/ours"
  export CLOUDSDK_CONFIG="$own"
  gcloud_log_in
  export CLOUDSDK_CONFIG="$ours"
  log_in

  # The login URL, then the code's exchange: gcloud's first, then ours
  for selected in '.path == "/auth"' '.params.grant_type == "authorization_code"'; do
    run -0 requests "$selected"
    assert_equal "${#lines[@]}" 2
    assert_equal "${lines[1]}" "${lines[0]}"
  done

  # gcloud keeps the scopes of its own login with the credentials, and none of the refresh token it's handed. Then a
  # refresh asks for none, and Google grants those the user consented to; reauthentication, which would ask for them,
  # fails either way without a prompt, which Claude's commands can't answer.
  diff <(credentials "$own" | jq -cS 'del(.scopes)') <(credentials "$ours" | jq -cS 'del(.scopes)')
  diff <(jq -S . "$own/application_default_credentials.json") <(jq -S . "$ours/application_default_credentials.json")
  diff -r -x logs -x '.last_*' -x '*.db' -x application_default_credentials.json "$own" "$ours"
}

#  With the fakes
#-----------------------------------------------
@test "finish, in a process of its own, exchanges the code with what start left in files, and ends logged in with ADC" {
  fake_google
  run -0 "$script" start
  run -0 "$script" finish "$(log_in_at "${lines[1]}")"
  assert_equal "$output" "gcloud CLI's account: user@example.com"$'\n'"ADC: valid"
}

@test "only ADC's owner can read it" {
  fake_google
  log_in
  [ -n "$(find "$CLOUDSDK_CONFIG/application_default_credentials.json" -perm 600)" ]
}

@test "finish with a wrong code keeps the login waiting, for a new code from the same URL" {
  fake_google
  run -0 "$script" start
  local url="${lines[1]}"
  run -1 "$script" finish wrong-code
  assert_line --index 0 "Google didn't take the code: invalid_grant: Malformed auth code."
  run -0 "$script" start
  assert_equal "${lines[1]}" "$url"
  run -0 "$script" finish "$(log_in_at "$url")"
  assert_equal "${lines[0]}" "gcloud CLI's account: user@example.com"
}

@test "start after a finished login starts a new one" {
  fake_google
  run -0 "$script" start
  local url="${lines[1]}"
  run -0 "$script" finish "$(log_in_at "$url")"
  run -0 "$script" start
  refute_line --index 1 "$url"
}

@test "no gcloud call gets the placeholder token, which status reports" {
  fake_google
  export CLOUDSDK_AUTH_ACCESS_TOKEN=proxy-injected
  log_in
  assert_equal "${lines[0]}" "gcloud CLI's account: user@example.com"
  assert_line --index 2 --partial 'CLOUDSDK_AUTH_ACCESS_TOKEN is set:'
  run -0 "$script" revoke
  run -1 grep '^placeholder:' "$CLOUDSDK_CONFIG/calls"
}

@test "revoke revokes ADC before the CLI's credentials, and leaves neither" {
  fake_google
  log_in
  run -0 "$script" revoke
  assert_equal "${lines[-1]}" 'No credentials of the gcloud CLI or ADC are left'
  diff <(grep revoke "$CLOUDSDK_CONFIG/calls") - <<< $'auth application-default revoke --quiet\nauth revoke --all --quiet'
}

@test "revoke fails when credentials are left" {
  fake_google
  export FAKE_GCLOUD_KEEP_ADC=1
  log_in
  run -1 "$script" revoke
  assert_equal "${lines[-1]}" "Left unrevoked: ADC's file $CLOUDSDK_CONFIG/application_default_credentials.json"
}
