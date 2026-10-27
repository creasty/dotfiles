#!/usr/bin/env bats
#
# ../setup, run as a cloud session's setup script runs it, on the checkout's files served over HTTP (DOTFILES_URL)

bats_require_minimum_version 1.7.0
bats_load_library bats-support
bats_load_library bats-assert

setup() {
  repo="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  served="$BATS_TEST_TMPDIR/served"
  mkdir "$served"
  copy_served
  serve
}

teardown() {
  [ -z "${server:-}" ] || kill "$server"
}

# Copies the files the setup downloads to the directory served
copy_served() {
  rm -rf "${served:?}"/*
  (cd "$repo" && cp -R --parents home/claude cloud/claude "$served")
}

# Serves it on a free port, as raw.githubusercontent.com serves the repository: a missing file is a 404
serve() {
  python3 - "$served" > "$BATS_TEST_TMPDIR/port" 2> /dev/null 3>&- <<'EOF' &
import functools, http.server, sys
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=sys.argv[1])
server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
print(server.server_address[1], flush=True)
server.serve_forever()
EOF
  server=$!
  for _ in $(seq 50); do
    [ -s "$BATS_TEST_TMPDIR/port" ] && break
    sleep 0.1
  done
  DOTFILES_URL="http://127.0.0.1:$(cat "$BATS_TEST_TMPDIR/port")"
  export DOTFILES_URL
}

# Ubuntu's, as on a cloud session's VM: a non-interactive shell returns before the rest
UBUNTU_BASHRC=/etc/skel/.bashrc

@test "it writes CLAUDE.md, and settings.json without the Mac's shell" {
  run -0 "$repo/cloud/claude/setup"
  cmp "$repo/home/claude/CLAUDE.md" ~/.claude/CLAUDE.md
  diff <(jq -S 'del(.env.CLAUDE_CODE_SHELL)' "$repo/home/claude/settings.json") <(jq -S . ~/.claude/settings.json)
}

@test "it writes every file of the skills, the executables executable" {
  run -0 "$repo/cloud/claude/setup"
  diff -r "$repo/cloud/claude/skills" ~/.claude/skills
  diff <(cd "$repo/cloud/claude/skills" && find . -type f -perm -u+x | sort) \
    <(cd ~/.claude/skills && find . -type f -perm -u+x | sort)
}

@test "a non-interactive shell drops the placeholder token" {
  cp "$UBUNTU_BASHRC" ~/.bashrc
  run -0 "$repo/cloud/claude/setup"
  # shellcheck disable=SC2016 # expanded by that bash
  run -0 env CLOUDSDK_AUTH_ACCESS_TOKEN=proxy-injected bash -c '. ~/.bashrc; echo "${CLOUDSDK_AUTH_ACCESS_TOKEN-unset}"'
  assert_equal "$output" unset
}

@test "a second run leaves ~/.bashrc as the first did" {
  cp "$UBUNTU_BASHRC" ~/.bashrc
  run -0 "$repo/cloud/claude/setup"
  run -0 "$repo/cloud/claude/setup"
  diff <(printf '%s\n' 'unset CLOUDSDK_AUTH_ACCESS_TOKEN'; cat "$UBUNTU_BASHRC") ~/.bashrc
}

@test "an empty or missing ~/.bashrc gets the unset alone" {
  : > ~/.bashrc
  run -0 "$repo/cloud/claude/setup"
  assert_equal "$(cat ~/.bashrc)" 'unset CLOUDSDK_AUTH_ACCESS_TOKEN'

  rm ~/.bashrc
  run -0 "$repo/cloud/claude/setup"
  assert_equal "$(cat ~/.bashrc)" 'unset CLOUDSDK_AUTH_ACCESS_TOKEN'
}

# So that a session doesn't start without them
@test "any failed download fails the setup" {
  local file passed_without=''
  for file in home/claude/CLAUDE.md home/claude/settings.json $(cd "$repo" && find cloud/claude/skills -type f); do
    copy_served
    rm "$served/$file"
    "$repo/cloud/claude/setup" 2> /dev/null && passed_without+="$file"$'\n'
  done
  assert_equal "$passed_without" ''
}

# On a Mac, ~/.claude and ~/.bashrc link into the checkout
@test "it refuses to run on a Mac, and writes nothing" {
  mkdir "$BATS_TEST_TMPDIR/bin"
  printf '#!/bin/sh\necho Darwin\n' > "$BATS_TEST_TMPDIR/bin/uname"
  chmod +x "$BATS_TEST_TMPDIR/bin/uname"
  run -1 env PATH="$BATS_TEST_TMPDIR/bin:$PATH" "$repo/cloud/claude/setup"
  assert_output --partial "for a cloud session's VM"
  run -0 ls -A "$HOME"
  refute_output
}
