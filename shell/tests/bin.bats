#!/usr/bin/env bats
#
# The commands in bin/ but git-*, run in the test's directory, with fakes of what they'd reach
# outside it: Claude Code, Docker, Facebook, Finder and the browser, notifications, peco's picking and kill

load helper

setup() {
  PATH="$BATS_TEST_TMPDIR/fakes:$DOTFILES_PATH/bin:$PATH"
  cd "$BATS_TEST_TMPDIR" || return
}

#  Docker
#-----------------------------------------------
@test "ctop runs ctop's image on Docker's socket, removed when it exits" {
  fake docker
  run -0 ctop
  assert_equal "$(calls)" 'docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock --name ctop quay.io/vektorlab/ctop:latest'
}

@test "texlive runs the command in TeX Live's image, in the current directory" {
  fake docker
  mkdir 'my paper'
  cd 'my paper'
  run -0 texlive latexmk -pdf 'main file.tex'
  assert_equal "$(calls)" "docker run --rm -it -w /workdir -v '$PWD:/workdir' creasty/texlive:latest latexmk -pdf 'main file.tex'"
}

@test "docker-clean removes the exited containers but volume ones, and the dangling images" {
  fake docker 'case $1 in
    ps) printf "%s\n" web-1 build data-volume ;;
    images) printf "%s\n" 0123abcd 4567ef01 ;;
  esac'
  run -0 docker-clean
  assert_equal "$(calls)" "docker ps -a --filter status=exited --format '{{ .Names }}'
docker rm web-1 build
docker images -f dangling=true -q
docker rmi 0123abcd 4567ef01"
}

@test "docker-clean goes on to the dangling images when only volume containers exited" {
  fake docker 'case $1 in
    ps) echo data-volume ;;
    images) echo 0123abcd ;;
  esac'
  run -0 docker-clean
  assert_equal "$(calls)" "docker ps -a --filter status=exited --format '{{ .Names }}'
docker images -f dangling=true -q
docker rmi 0123abcd"
}

@test "docker-clean, with nothing to remove, removes nothing" {
  fake docker
  run -0 docker-clean
  assert_equal "$(calls)" "docker ps -a --filter status=exited --format '{{ .Names }}'
docker images -f dangling=true -q"
}

@test "docker-ips lists the running containers' IP addresses and names" {
  local format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} {{ .Name }}'
  fake docker 'case $1 in
    ps) printf "%s\n" 0123abcd 4567ef01 ;;
    inspect) [ "$4" = 0123abcd ] && echo "172.17.0.2 /web" || echo "172.18.0.3 /db" ;;
  esac'
  run -0 docker-ips
  assert_equal "$output" $'172.17.0.2\tweb\n172.18.0.3\tdb'
  assert_equal "$(calls)" "docker ps -q
docker inspect --format '$format' 0123abcd
docker inspect --format '$format' 4567ef01"
}

@test "docker-ips, with no container running, prints nothing" {
  fake docker
  run -0 docker-ips
  refute_output
  assert_equal "$(calls)" 'docker ps -q'
}

@test "gcloud-pubsub start starts the emulator's container, and waits for it" {
  fake docker
  fake sleep
  run -0 gcloud-pubsub start
  assert_equal "$output" $'==> Starting server\n==> Waiting for ready\nready'
  assert_equal "$(calls)" $'docker start the-pubsub\nsleep 5'
}

@test "gcloud-pubsub start creates the emulator's container on port 8085 when there's none" {
  unset PORT
  fake docker '[ "$1" != start ] || { echo "Error: No such container: $2" >&2; exit 1; }'
  fake sleep
  run -0 gcloud-pubsub start
  assert_equal "$output" $'==> Starting server\n==> Creating server\n==> Waiting for ready\nready'
  assert_equal "$(calls)" 'docker start the-pubsub
docker run --name the-pubsub -d -p 8085:8085 -it google/cloud-sdk:latest gcloud beta emulators pubsub start --host-port=0.0.0.0:8085
sleep 5'
}

@test "gcloud-pubsub start creates the emulator's container on PORT" {
  export PORT=9000
  fake docker '[ "$1" != start ] || exit 1'
  fake sleep
  run -0 gcloud-pubsub start
  run -0 calls
  assert_line 'docker run --name the-pubsub -d -p 9000:9000 -it google/cloud-sdk:latest gcloud beta emulators pubsub start --host-port=0.0.0.0:9000'
}

@test "gcloud-pubsub stop, destroy and env-init act on the emulator's container" {
  fake docker
  run -0 gcloud-pubsub stop
  run -0 gcloud-pubsub destroy
  run -0 gcloud-pubsub env-init
  assert_equal "$(calls)" 'docker stop the-pubsub
docker rm the-pubsub
docker exec -it the-pubsub gcloud beta emulators pubsub env-init'
}

@test "gcloud-pubsub, without a command it knows, prints its usage and fails" {
  fake docker
  local usage='gcloud-pubsub <command>

COMMANDS:
    gcloud-pubsub start
    gcloud-pubsub stop
    gcloud-pubsub destroy
    gcloud-pubsub env-init'
  run -1 gcloud-pubsub
  assert_equal "$output" "$usage"
  run -1 gcloud-pubsub restart
  assert_equal "$output" "$usage"
  assert_equal "$(calls)" ''
}

@test "redis start starts Redis's container" {
  fake docker
  run -0 redis start
  assert_equal "$(calls)" 'docker start the-redis'
}

@test "redis start creates Redis's container, its data in ~/.docker-data, when there's none" {
  export HOME="$BATS_TEST_TMPDIR/my home"
  fake docker '[ "$1" != start ] || exit 1'
  run -0 redis start
  assert_equal "$(calls)" "docker start the-redis
docker run -p 6379:6379 --name the-redis -v '$HOME/.docker-data/the-redis:/data' -d redis:alpine"
}

@test "redis cli runs redis-cli in Redis's container, with the arguments" {
  fake docker
  run -0 redis cli SET greeting 'hello world'
  assert_equal "$(calls)" "docker exec -it the-redis redis-cli SET greeting 'hello world'"
}

@test "redis stop and destroy act on Redis's container" {
  fake docker
  run -0 redis stop
  run -0 redis destroy
  assert_equal "$(calls)" $'docker stop the-redis\ndocker rm the-redis'
}

@test "redis, without a command it knows, prints its usage and fails" {
  fake docker
  local usage='redis <command>

COMMANDS:
    redis start
    redis stop
    redis destroy
    redis cli'
  run -1 redis
  assert_equal "$output" "$usage"
  run -1 redis restart
  assert_equal "$output" "$usage"
  assert_equal "$(calls)" ''
}

@test "mysql-server start starts MySQL's container" {
  fake docker
  run -0 mysql-server start
  assert_equal "$(calls)" 'docker start the-mysql'
}

@test "mysql-server start creates MySQL's container, its data in ~/.docker-data, when there's none" {
  local home="$BATS_TEST_TMPDIR/my home"
  fake docker '[ "$1" != start ] || exit 1'
  HOME="$home" run -0 mysql-server start
  assert_equal "$(calls)" "docker start the-mysql
docker run -p 3306:3306 --name the-mysql -e MYSQL_ROOT_PASSWORD=password -v '$home/.docker-data/the-mysql:/var/lib/mysql' -d mysql:8.0"
}

@test "mysql-server stop and destroy act on MySQL's container" {
  fake docker
  run -0 mysql-server stop
  run -0 mysql-server destroy
  assert_equal "$(calls)" $'docker stop the-mysql\ndocker rm the-mysql'
}

@test "mysql-server, without a command it knows, prints its usage and fails" {
  fake docker
  local usage='mysql-server <command>

COMMANDS:
    mysql-server start
    mysql-server stop
    mysql-server destroy'
  run -1 mysql-server
  assert_equal "$output" "$usage"
  run -1 mysql-server restart
  assert_equal "$output" "$usage"
  assert_equal "$(calls)" ''
}

#  fb-testusr
#-----------------------------------------------
@test "fb-testusr creates a Facebook test user with the app's token, and sets its password" {
  export FACEBOOK_APP_ID=1234 FACEBOOK_APP_SECRET=app-secret FACEBOOK_APP_TEST_PASSWORD=test-password
  echo '{"access_token": "app-token", "token_type": "bearer"}' > token.json
  echo '{"id": "5678", "email": "john_smith@tfbnw.net"}' > user.json
  fake curl 'case $3 in
    */oauth/access_token) cat token.json ;;
    */accounts/test-users) cat user.json ;;
    *) echo "{\"success\": true}" ;;
  esac'
  run -0 fb-testusr
  assert_equal "$output" 'token:    app-token
id:       5678
email:    john_smith@tfbnw.net
password: test-password'
  assert_equal "$(calls)" 'curl -X POST https://graph.facebook.com/oauth/access_token -s -d client_id=1234 -d client_secret=app-secret -d grant_type=client_credentials
curl -X POST https://graph.facebook.com/v2.8/1234/accounts/test-users -s -d access_token=app-token -d name=John%20Smith -d installed=true -d locale=ja_JP -d permissions=read_stream
curl -X POST https://graph.facebook.com/v2.8/5678 -s -d access_token=app-token -d password=test-password'
}

@test "fb-testusr, without the app's ID and secret, fails before reaching Facebook" {
  unset FACEBOOK_APP_ID FACEBOOK_APP_SECRET FACEBOOK_APP_TEST_PASSWORD
  fake curl
  run -1 fb-testusr
  assert_output --partial 'FACEBOOK_APP_ID: unbound variable'
  assert_equal "$(calls)" ''
}

#  finder
#-----------------------------------------------
# Keeps the directory osascript gets, and compiles its script without running it
fake_finder_script() {
  fake osascript 'printf %s "$3" > "$BATS_TEST_TMPDIR/target"; /usr/bin/osacompile -e "$2" -o "$BATS_TEST_TMPDIR/finder.scpt"'
}

@test "finder shows the current directory in Finder" {
  fake_finder_script
  mkdir project
  cd project
  run -0 finder
  assert_equal "$(< "$BATS_TEST_TMPDIR/target")" "$BATS_TEST_TMPDIR/project/"
}

@test "finder shows a directory it's given by a relative path" {
  fake_finder_script
  mkdir -p 'my project/docs'
  run -0 finder 'my project/docs'
  assert_equal "$(< "$BATS_TEST_TMPDIR/target")" "$BATS_TEST_TMPDIR/my project/docs/"
}

@test "finder hands anything else to open, with all its arguments" {
  fake open
  touch notes.txt
  run -0 finder -R notes.txt
  assert_equal "$(calls)" 'open -R notes.txt'
}

#  localpush
#-----------------------------------------------
# Prints the title and message of the notification the script would show, as AppleScript reads them, without showing
# it: display notification <message> [with title <title>] becomes
# return "title: " & <title> & linefeed & "message: " & <message>
fake_notification() {
  fake osascript "$(
    cat << 'EOF'
literal='"([^"\\]|\\.)*"'
pattern="^display notification ($literal)( with title ($literal))?\$"
[[ $1 == -e && $# -eq 2 && $2 =~ $pattern ]] || { echo "unexpected: $*" >&2; exit 1; }
script="\"message: \" & ${BASH_REMATCH[1]}"
[ -z "${BASH_REMATCH[3]}" ] || script="\"title: \" & ${BASH_REMATCH[4]} & linefeed & $script"
exec /usr/bin/osascript -e "return $script"
EOF
  )"
}

@test "localpush shows the title and message as they are, quotes, backslashes, newlines and emoji included" {
  fake_notification
  local title='Build "web" \ done' message=$'C:\\new\\top\t"dist"\n2 files: 完了 🎉'
  run -0 localpush "$title" "$message"
  assert_equal "$output" "title: $title"$'\n'"message: $message"
}

@test "localpush with one argument shows it as the title, with no message" {
  fake_notification
  run -0 localpush Deployed
  assert_equal "$output" $'title: Deployed\nmessage: '
}

@test "localpush without arguments shows a notification with no title or message" {
  fake_notification
  run -0 localpush
  assert_equal "$output" 'message: '
}

#  grep-kill
#-----------------------------------------------
# PIDs on macOS stay below 100000: no process has the ones here

# The calls the fakes logged, sorted: the commands of a pipeline start in no order
sorted_calls() {
  calls | sort
}

@test "grep-kill kills the processes picked in peco from procs, with the arguments as the query" {
  fake procs "printf '%s\n' '999991 me  0.0  node server.js' '999992 me  0.0  vim notes.md'"
  # The lines with the query, as Enter picks the one match
  fake peco 'grep -F -- "$2"'
  fake kill
  run -0 --separate-stderr grep-kill node server
  assert_equal "$stderr" '999991 me  0.0  node server.js'
  assert_equal "$(sorted_calls)" "kill -9 999991
peco --query 'node server'
procs --no-header --sorta cpu --nand $DOTFILES_PATH/bin/grep-kill"
}

@test "grep-kill, without procs, picks from ps without its header and its own process" {
  fake ps "printf '%s\n' 'USER PID %CPU COMMAND' 'me 999991 0.0 node server.js' 'me 999992 0.0 vim notes.md' \
    'me 999993 0.0 /bin/bash $DOTFILES_PATH/bin/grep-kill node'"
  fake peco 'tee peco.in | grep -F -- "$2"'
  fake kill
  PATH="$BATS_TEST_TMPDIR/fakes:/usr/bin:/bin"
  run -0 --separate-stderr "$DOTFILES_PATH/bin/grep-kill" node
  assert_equal "$(< peco.in)" $'me 999991 0.0 node server.js\nme 999992 0.0 vim notes.md'
  assert_equal "$stderr" 'me 999991 0.0 node server.js'
  assert_equal "$(sorted_calls)" $'kill -9 999991\npeco --query node\nps aux'
}

@test "grep-kill, with nothing picked, kills nothing" {
  fake procs "echo '999991 me  0.0  node server.js'"
  fake peco
  fake kill
  run -0 grep-kill
  assert_equal "$(sorted_calls)" "peco --query ''
procs --no-header --sorta cpu --nand $DOTFILES_PATH/bin/grep-kill"
}

#  p-value
#-----------------------------------------------
# Its output without the escape sequences that make it bold and gray
p_value() {
  set -o pipefail
  p-value "$@" | sed $'s/\e\\[[0-9;]*m//g'
}

# The p-values are R's, prop.test(c(x1, x2), c(n1, n2))$p.value, computed in Python from its formula: the chi-squared
# statistic with Yates' correction, which is capped at |x - E|, and erfc(sqrt(chi2 / 2)) for its 1 degree of freedom
@test "p-value finds a rise from 15% of 200 to 25% of 240 strong evidence" {
  run -0 p_value 30/200 60/240
  assert_equal "$output" '   Rate:  15.00 → 25.00% ⬆️
          +10.0pt, +66.7%
P-value:  0.01349 👍
          <0.05 strong evidence'
}

@test "p-value finds a fall from 13% to 10% of 1000 marginal" {
  run -0 p_value 130/1000 100/1000
  assert_equal "$output" '   Rate:  13.00 → 10.00% ⬇️
          -3.0pt, -23.1%
P-value:  0.04209 🤷
          ~0.05 marginal'
}

@test "p-value finds a rise from 10% to 11% of 1000 weak evidence" {
  run -0 p_value 100/1000 110/1000
  assert_equal "$output" '   Rate:  10.00 → 11.00% ⬆️
          +1.0pt, +10.0%
P-value:  0.51152 👎
          >0.05 weak evidence'
}

@test "p-value finds no evidence in the same rate, a p-value of 1" {
  run -0 p_value 10/100 10/100
  assert_equal "$output" '   Rate:  10.00 → 10.00% ➡️
          +0.0pt, +0.0%
P-value:  1.00000 👎
          >0.05 weak evidence'
}

@test "p-value, without two N/D arguments, prints its usage and fails" {
  run -1 --separate-stderr p-value
  assert_equal "${stderr_lines[0]}" 'p-value N1/D1 N2/D2'
  run -1 --separate-stderr p-value 30/200
  assert_equal "${stderr_lines[0]}" 'p-value N1/D1 N2/D2'
  run -1 --separate-stderr p-value 30 50/200
  assert_equal "${stderr_lines[0]}" 'p-value N1/D1 N2/D2'
  refute_output
}

#  claude-spawn
#-----------------------------------------------
# A home with the checkout creasty/site, whose login shell finds the fake claude first, as it would the real one.
# The fake logs its calls, their folders and the CLAUDE_* variables they got. Its -p makes the worktree --worktree
# names, locked as claude locks it, and answers with a session id, or fails (fail).
spawn_home() {
  export HOME="$BATS_TEST_TMPDIR/home" SHELL="$LOGIN_ZSH"
  SITE="$HOME/go/src/github.com/creasty/site"
  mkdir -p "$SITE"
  git -C "$SITE" init -q
  git -C "$SITE" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m init
  echo "path=($(q "$BATS_TEST_TMPDIR/fakes") \$path)" > "$HOME/.zprofile"
  fake claude 'pwd -P >> "$HOME/claude-pwd"
env | grep ^CLAUDE >> "$HOME/claude-env"
if [ "$1" = -p ]; then
  [ -e "$HOME/fail" ] && { echo "Not logged in"; exit 1; }
  while [ $# -gt 0 ]; do
    if [ "$1" = --worktree ]; then
      git worktree add -q -b "worktree-$2" ".claude/worktrees/$2"
      git worktree lock --reason "claude session $2" ".claude/worktrees/$2"
    fi
    shift
  done
  echo "{\"session_id\":\"0b6f3a1e-4c2d-4e8f-9a1b-2c3d4e5f6a7b\"}"
fi'
}

@test "claude-spawn opens a session made in a new worktree of an owner/repo checkout in the desktop app, as a new terminal would" {
  spawn_home
  export CLAUDE_CODE_CHILD_SESSION=1
  run -0 claude-spawn creasty/site
  assert_output --regexp "^local_0b6f3a1e-4c2d-4e8f-9a1b-2c3d4e5f6a7b $(cd "$SITE" && pwd -P)/\.claude/worktrees/spawn-[0-9a-f]{6}\$"
  local name="${output##*/}"
  run -0 calls
  assert_line --index 0 --regexp "^claude -p --worktree $name --output-format json "
  assert_line --index 1 'claude --desktop --resume 0b6f3a1e-4c2d-4e8f-9a1b-2c3d4e5f6a7b'
  # -p in the checkout; --desktop in the worktree, which is the app's own kind: unlocked, on a claude/ branch
  assert_equal "$(cat "$HOME/claude-pwd")" "$(cd "$SITE" && pwd -P)
$(cd "$SITE/.claude/worktrees/$name" && pwd -P)"
  run -0 git -C "$SITE" worktree list --porcelain
  refute_output --partial locked
  assert_output --partial "branch refs/heads/claude/$name"
  refute_output --partial "worktree-$name"
  assert_equal "$(cat "$HOME/claude-env")" ''
}

@test "claude-spawn names the session after the title, and its worktree after the title's first words" {
  spawn_home
  run -0 claude-spawn creasty/site 'Knowledge bases built on OWL/RDF'
  assert_output --regexp "/\.claude/worktrees/knowledge-bases-built-on-[0-9a-f]{6}\$"
  local name="${output##*/}"
  run -0 calls
  assert_line --index 0 --regexp "^claude -p --name 'Knowledge bases built on OWL/RDF' --worktree $name --output-format json "
  # A title without ASCII words names the worktree as no title does
  run -0 claude-spawn creasty/site 'オントロジーの調査'
  assert_output --regexp "/\.claude/worktrees/spawn-[0-9a-f]{6}\$"
}

@test "claude-spawn, in a folder outside git, opens the session made in the folder itself" {
  spawn_home
  mkdir "$HOME/notes"
  run -0 claude-spawn "$HOME/notes"
  assert_output "local_0b6f3a1e-4c2d-4e8f-9a1b-2c3d4e5f6a7b $HOME/notes"
  run -0 calls
  assert_line --index 0 --regexp '^claude -p --output-format json '
  assert_equal "$(cat "$HOME/claude-pwd")" "$(cd "$HOME/notes" && pwd -P)
$(cd "$HOME/notes" && pwd -P)"
}

@test "claude-spawn, when claude fails, opens nothing in the desktop app" {
  spawn_home
  touch "$HOME/fail"
  run -1 --separate-stderr claude-spawn creasty/site
  refute_output
  assert_equal "$stderr" "claude-spawn: claude failed in $SITE: Not logged in"
  assert_equal "$(calls | grep -c -- --desktop)" 0
}

@test "claude-spawn, given a folder that isn't there, starts nothing" {
  spawn_home
  run -1 --separate-stderr claude-spawn creasty/nothing
  assert_equal "$stderr" 'claude-spawn: no folder creasty/nothing'
  assert_equal "$(calls)" ''
}

@test "claude-spawn, given -h or no folder, shows its description and synopsis and starts nothing" {
  spawn_home
  run -1 claude-spawn -h
  assert_line --index 0 --partial 'Start a Claude Code session in a folder'
  assert_line 'Synopsis:'
  assert_line '    claude-spawn [-h] <owner/repo | path> [title]'
  local help="$output"
  run -1 claude-spawn
  assert_output "$help"
  assert_equal "$(calls)" ''
}

#  Files
#-----------------------------------------------
@test "dataurl makes a text file's data URL, in UTF-8" {
  printf 'こんにちは, world\n' > 'hello world.txt'
  run -0 dataurl 'hello world.txt'
  assert_output --regexp '^data:text/plain;charset=utf-8;base64,'
  base64 -d <<< "${output#*,}" | cmp - 'hello world.txt'
}

@test "dataurl makes a binary file's data URL, on a line, whose data decodes to the same bytes" {
  local i
  # A PNG of a pixel, followed by every byte
  {
    base64 -d <<< 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='
    for i in $(seq 0 255); do
      # shellcheck disable=SC2059 # the byte's escape
      printf "\\$(printf %03o "$i")"
    done
  } > pixel.png
  run -0 dataurl pixel.png
  assert_equal "${#lines[@]}" 1
  assert_output --regexp '^data:image/png;base64,'
  base64 -d <<< "${output#*,}" | cmp - pixel.png
}

@test "dataurl, given a file that isn't there, fails without a URL" {
  run -1 --separate-stderr dataurl missing.txt
  refute_output
}

@test "unpkcs splits a PKCS#12 file into its certificate, its key unencrypted and the CA's certificate" {
  # A CA, and a certificate it signed, in a file with a password
  openssl req -x509 -newkey rsa:2048 -nodes -keyout ca.key -out ca.pem -subj /CN=Test-CA -days 1 2> /dev/null
  openssl req -newkey rsa:2048 -nodes -keyout leaf.key -out leaf.csr -subj /CN=leaf.test 2> /dev/null
  openssl x509 -req -in leaf.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out leaf.pem -days 1 2> /dev/null
  openssl pkcs12 -export -in leaf.pem -inkey leaf.key -certfile ca.pem -out 'my bundle.p12' -passout pass:secret
  mkdir out
  cd out
  # openssl asks for the password on the terminal, which expect gives it. On lines of their own: expect takes a block
  # on one line for a pattern.
  run -0 expect -c '
    spawn unpkcs {../my bundle.p12}
    expect {
      "Import Password:" { send "secret\r"; exp_continue }
      timeout { exit 1 }
      eof
    }
    lassign [wait] pid id error status
    exit $status
  '
  # Each file has the one PEM block, after the attributes of its bag
  diff <(sed -n '/^-----BEGIN/,/^-----END/p' cert.pem) ../leaf.pem
  diff <(sed -n '/^-----BEGIN/,/^-----END/p' cert.key) ../leaf.key
  diff <(sed -n '/^-----BEGIN/,/^-----END/p' cacert.pem) ../ca.pem
}
