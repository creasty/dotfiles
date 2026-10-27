#!/usr/bin/env bats
#
# PostgreSQL's server of this machine, which the first switch set up in PGDATA (nix/modules/postgresql.nix)

# A test's STARTED reaches teardown(), which bats runs in the test's process
# shellcheck disable=SC2030,SC2031

load helper

@test "terminals get the server's data and connect as postgres" {
  run -0 login_zsh 'print -rl -- "$PGUSER" "$(< "$PGDATA/PG_VERSION")" "$(psql --version)"'
  assert_equal "${lines[0]}" postgres
  assert_line --index 2 --partial "psql (PostgreSQL) ${lines[1]}."
}

@test "pg_ctl starts the server, which takes postgres without a password and logs every statement" {
  # On a port of its own unless it's running: another server, such as a project's, may have 5432
  local port=''
  if ! login_zsh 'pg_ctl status' > /dev/null; then
    port=54329
    # To a file: the server keeps pg_ctl's output open, which `run` would wait on until it stops
    login_zsh "pg_ctl start --wait -o '-p $port'" > "$BATS_TEST_TMPDIR/start.log" 2>&1 || {
      cat "$BATS_TEST_TMPDIR/start.log" >&2
      return 1
    }
    STARTED=1
  fi

  local marker="verify-$$-$RANDOM"
  run -0 login_zsh "${port:+PGPORT=$port }psql --no-psqlrc --tuples-only --no-align --command=\"select '$marker'\""
  assert_equal "$output" "$marker"
  run -0 login_zsh "grep -F -- \"$marker\" \"\$PGDATA/log/server.log\""
}

teardown() {
  [ -z "${STARTED:-}" ] || login_zsh 'pg_ctl stop --wait' > /dev/null
}
