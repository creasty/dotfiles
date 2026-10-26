#!/usr/bin/env bash
# Logs gcloud in with the user's own account in a Claude Code cloud session, which has no browser.
#
#   gcloud-login.sh start          Starts the login and prints the URL for the user to open
#   gcloud-login.sh finish <code>  Finishes it with the verification code the browser shows
#   gcloud-login.sh status         Shows the login, and the variables in the way of it
#   gcloud-login.sh revoke         Revokes the gcloud CLI's credentials and ADC
#
# Claude's commands take no input, so gcloud runs detached from the session, and the code reaches it through a named
# pipe. No token is printed.

set -euo pipefail

STATE_DIR="${TMPDIR:-/tmp}/gcloud-login-$(id -u)"
FIFO="$STATE_DIR/code.fifo"
LOG="$STATE_DIR/login.log"
PID_FILE="$STATE_DIR/pid"
EXIT_FILE="$STATE_DIR/exit"
# How long the login waits for the code before it's dropped
LOGIN_TIMEOUT_SECONDS=900
ADC_FILE="${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}/application_default_credentials.json"

# gcloud prefers a cloud session's placeholder token to the account it's logged in to: status reports whether the
# session still has it
PLACEHOLDER="${CLOUDSDK_AUTH_ACCESS_TOKEN:+set}"
unset CLOUDSDK_AUTH_ACCESS_TOKEN

login_running() {
  [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

login_url() {
  grep -o 'https://accounts\.google\.com/[^[:space:]]*' "$LOG" 2>/dev/null | head -1
}

do_start() {
  if login_running; then
    echo "A login is already running. Write this URL in full in your reply's text for the user:"
    login_url
    return
  fi

  rm -rf "$STATE_DIR"
  mkdir -m 700 -p "$STATE_DIR"
  mkfifo -m 600 "$FIFO"

  # Opened for both reading and writing, the pipe gives gcloud's input no EOF until the code arrives
  setsid nohup bash -c 'exec 3<>"$1"; timeout "$2" gcloud auth login --no-launch-browser --update-adc <&3; echo $? > "$3"' \
    _ "$FIFO" "$LOGIN_TIMEOUT_SECONDS" "$EXIT_FILE" > "$LOG" 2>&1 < /dev/null &
  echo $! > "$PID_FILE"

  for _ in $(seq 30); do
    if [ -n "$(login_url)" ]; then
      echo "Write this URL in full in your reply's text for the user, and take the verification code shown after they log in:"
      login_url
      return
    fi
    if ! login_running; then
      break
    fi
    sleep 1
  done

  echo "No login URL came. gcloud's output:" >&2
  cat "$LOG" >&2
  exit 1
}

do_finish() {
  local code="${1:?pass the verification code}"
  if ! login_running; then
    echo "No login is running (it expired or never started): start again" >&2
    exit 1
  fi

  printf '%s\n' "$code" > "$FIFO"

  local pid
  pid="$(cat "$PID_FILE")"
  for _ in $(seq 60); do
    kill -0 "$pid" 2>/dev/null || break
    sleep 1
  done
  if kill -0 "$pid" 2>/dev/null; then
    echo "gcloud hasn't finished. Its output:" >&2
    cat "$LOG" >&2
    exit 1
  fi

  if [ "$(cat "$EXIT_FILE" 2>/dev/null)" != 0 ]; then
    echo "The login failed. gcloud's output:" >&2
    cat "$LOG" >&2
    exit 1
  fi
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
  # The ADC of `login --update-adc` holds the gcloud CLI's refresh token. Revoked after the CLI's, ADC's revoke gets
  # invalid_token from the server and fails without deleting its file, so ADC goes first. The CLI's revoke then takes
  # invalid_token as already revoked, warns "already inactive" and deletes the credentials.
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
