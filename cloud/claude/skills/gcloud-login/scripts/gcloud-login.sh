#!/usr/bin/env bash
# Logs gcloud in with the user's own account in a Claude Code cloud session, which has no browser.
#
#   gcloud-login.sh start          Starts the login and prints the URL for the user to open
#   gcloud-login.sh finish <code>  Finishes it with the verification code the browser shows
#   gcloud-login.sh status         Shows the login, and the variables in the way of it
#   gcloud-login.sh revoke         Revokes the gcloud CLI's credentials and ADC
#
# The VM can pause while the user logs in, which ends its processes and keeps its files, so the login waits in files:
# start keeps the PKCE code verifier, and finish exchanges the code with it, as `gcloud auth login --no-launch-browser
# --update-adc` would, then hands the refresh token to gcloud and writes ADC. No token is printed.

set -euo pipefail

STATE_DIR="$HOME/.local/state/gcloud-login"
VERIFIER="$STATE_DIR/verifier"
URL_FILE="$STATE_DIR/url"
ADC_FILE="${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}/application_default_credentials.json"

# What gcloud's login URL asks for besides its client and PKCE challenge (tests/gcloud-login.bats compares the two)
REDIRECT_URI=https://sdk.cloud.google.com/authcode.html
SCOPES=(
  openid
  https://www.googleapis.com/auth/userinfo.email
  https://www.googleapis.com/auth/cloud-platform
  https://www.googleapis.com/auth/appengine.admin
  https://www.googleapis.com/auth/sqlservice.login
  https://www.googleapis.com/auth/compute
  https://www.googleapis.com/auth/accounts.reauth
)

# gcloud prefers a cloud session's placeholder token to the account it's logged in to: status reports whether the
# session still has it
PLACEHOLDER="${CLOUDSDK_AUTH_ACCESS_TOKEN:+set}"
unset CLOUDSDK_AUTH_ACCESS_TOKEN

base64url() {
  base64 | tr '+/' '-_' | tr -d '=\n'
}

do_start() {
  if [ -f "$URL_FILE" ]; then
    echo "A login is already waiting for its code. Write this URL in full in your reply's text for the user:"
    cat "$URL_FILE"
    return
  fi

  local auth_host client_id verifier challenge url
  auth_host="$(gcloud config get auth/auth_host)"
  client_id="$(gcloud config get auth/client_id)"
  verifier="$(openssl rand 48 | base64url)"
  challenge="$(printf '%s' "$verifier" | openssl dgst -sha256 -binary | base64url)"
  url="$(jq -nr --arg auth_host "$auth_host" --arg client_id "$client_id" --arg redirect_uri "$REDIRECT_URI" \
    --arg scope "${SCOPES[*]}" --arg challenge "$challenge" '
    {response_type: "code", client_id: $client_id, redirect_uri: $redirect_uri, scope: $scope, prompt: "consent",
      token_usage: "remote", access_type: "offline", code_challenge: $challenge, code_challenge_method: "S256"}
    | $auth_host + "?" + (to_entries | map("\(.key)=\(.value | @uri)") | join("&"))')"

  mkdir -m 700 -p "$STATE_DIR"
  printf '%s' "$verifier" > "$VERIFIER"
  echo "$url" > "$URL_FILE"
  echo "Write this URL in full in your reply's text for the user, and take the verification code shown after they log in:"
  echo "$url"
}

do_finish() {
  local code="${1:?pass the verification code}"
  if [ ! -f "$VERIFIER" ]; then
    echo "No login is waiting for its code: start one" >&2
    exit 1
  fi

  local client_id client_secret token_host response
  client_id="$(gcloud config get auth/client_id)"
  client_secret="$(gcloud config get auth/client_secret)"
  token_host="$(gcloud config get auth/token_host)"
  # The response holds the tokens, which go to jq and gcloud through their input
  response="$(curl -sS --data-urlencode grant_type=authorization_code --data-urlencode "code=$code" \
    --data-urlencode "code_verifier@$VERIFIER" --data-urlencode "redirect_uri=$REDIRECT_URI" \
    --data-urlencode "client_id=$client_id" --data-urlencode "client_secret=$client_secret" "$token_host")"
  if ! jq -e .refresh_token > /dev/null 2>&1 <<< "$response"; then
    echo "Google didn't take the code: $(jq -r '[.error, .error_description] | map(values) | join(": ")' <<< "$response" 2>&1)" >&2
    echo "The user can open the same URL again for a new code" >&2
    exit 1
  fi

  local account out
  account="$(jq -r '.id_token | split(".")[1] | gsub("-"; "+") | gsub("_"; "/") | @base64d | fromjson | .email' \
    <<< "$response")"
  # gcloud takes the token from its input when the command line leaves it out, and refreshes it before keeping it
  if ! out="$(jq -r .refresh_token <<< "$response" | gcloud auth activate-refresh-token "$account" 2>&1)"; then
    echo "gcloud didn't take the login: $out" >&2
    exit 1
  fi
  (
    umask 077
    jq -S --arg client_id "$client_id" --arg client_secret "$client_secret" \
      '{type: "authorized_user", account: "", client_id: $client_id, client_secret: $client_secret, refresh_token,
        universe_domain: "googleapis.com"}' \
      <<< "$response" > "$ADC_FILE"
  )

  rm -rf "$STATE_DIR"
  do_status
}

do_status() {
  local account
  account="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null || true)"
  echo "gcloud CLI's account: ${account:-(none)}"

  if gcloud auth application-default print-access-token > /dev/null 2>&1; then
    echo "ADC: valid"
  else
    echo "ADC: invalid"
  fi

  if [ -n "$PLACEHOLDER" ]; then
    echo "CLOUDSDK_AUTH_ACCESS_TOKEN is set: run gcloud and the tools that call it with env -u CLOUDSDK_AUTH_ACCESS_TOKEN (SKILL.md)"
  fi
}

do_revoke() {
  # ADC holds the gcloud CLI's refresh token. Revoked after the CLI's, ADC's revoke gets invalid_token from the server
  # and fails without deleting its file, so ADC goes first. The CLI's revoke then takes invalid_token as already
  # revoked, warns "already inactive" and deletes the credentials.
  gcloud auth application-default revoke --quiet || true
  gcloud auth revoke --all --quiet || true
  do_status

  local remaining=()
  if [ -n "$(gcloud auth list --format='value(account)' 2>/dev/null)" ]; then
    remaining+=("the gcloud CLI's credentials")
  fi
  if [ -e "$ADC_FILE" ]; then
    remaining+=("ADC's file $ADC_FILE")
  fi
  if [ "${#remaining[@]}" -gt 0 ]; then
    echo "Left unrevoked: ${remaining[*]}" >&2
    exit 1
  fi
  echo "No credentials of the gcloud CLI or ADC are left"
}

case "${1:-}" in
  start) do_start ;;
  finish) shift; do_finish "$@" ;;
  status) do_status ;;
  revoke) do_revoke ;;
  *)
    sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
