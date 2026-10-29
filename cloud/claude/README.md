# Claude Code in the cloud

[Cloud sessions](https://code.claude.com/docs/en/claude-code-on-the-web) run on a VM without this Mac's `~/.claude`.
A [cloud environment](https://code.claude.com/docs/en/cloud-environments) set up as follows gives them the same `CLAUDE.md` and `settings.json` (`home/claude/`), and leaves out `rules/`, which holds what's true only on this Mac.
It also gives them the skills in [`skills/`](skills/) here, which only they need; `setup` fetches them a file at a time, so it lists each file.

Its setup script runs `setup` from the branch `DOTFILES_URL` points at, which downloads the rest from there too, writes them into the VM's `~/.claude`, and has gcloud use the account you log in with:

```bash
#!/bin/bash
set -o pipefail
export DOTFILES_URL=https://raw.githubusercontent.com/creasty/dotfiles/refs/heads/master
curl -fsSL $DOTFILES_URL/cloud/claude/setup | bash
```

To try a branch, put `refs/heads/<branch>` in place of `refs/heads/master`.

The default network access, Trusted, allows `raw.githubusercontent.com`.
A failed download fails the setup, so a session doesn't start without them.
A session has the files as the branch had them when its setup ran, give or take the 5 minutes `raw.githubusercontent.com` keeps them cached (`max-age=300`): a VM paused while idle keeps them, and one rebuilt after being reclaimed runs the setup again.

`settings.json` sets `GIT_AUTHOR_NAME` and `GIT_AUTHOR_EMAIL` to the identity in `config/git/config`, which makes you the author of the session's commits, so the environment needs no variables.
Leave the committer to the session, which signs its commits as Claude: GitHub checks a signature against the committer's keys, so a commit with `GIT_COMMITTER_*` set shows as unverified.

claude.ai's personal preferences hold the rest:

```text
Language:
- Reply in the language the request was written in. An English request gets an English reply.
- For code, comments, commit messages and PR bodies, follow the language the repository already uses.

When the output is Japanese:
- 句読点以外の数字・記号は半角文字を使うこと。ただし入力に全角が含まれており、エコーバックする場合のみ全角を使って良いとする。
```

## Tests

The `claude-cloud` job of the tests workflow runs [`tests/`](tests/) on Ubuntu 24.04, the OS of a cloud session's VM: `bats cloud/claude/tests`, on Linux with bats-support and bats-assert, curl, jq, Python and the Google Cloud CLI.
They run `setup` on the checkout's files, served over HTTP (`DOTFILES_URL`), and `gcloud-login.py` with the Google Cloud CLI and Google up to a login, which needs a person at Google's page, and with fakes of them ([`tests/fakes/`](tests/fakes/)) for a login and what follows one.
Since `gcloud-login.py` logs in the way gcloud's own login does, one test has both log in against the fake Google, and fails on any difference in what they ask Google or leave in gcloud's configuration directory, but for one it explains.

## Verification gaps

- **Cloud sessions**: no test runs one.
  Anthropic's docs say a cloud session doesn't read `~/.claude/settings.json`, yet it read the one the script writes (seen 2026-10-20): while it still does, `echo $DISABLE_COST_WARNINGS` in a session prints 1.
  They say the same of `~/.claude/skills/`, yet a session loaded the `gcloud-login` the script writes there, and logged in and out with it (seen 2026-10-29): while it still does, `/skills` in a session lists `gcloud-login`.
- **A login**: the fake Google plays Google's side of it, and the fake gcloud what gcloud does after one, including that ADC's revoke, after the CLI's, fails and keeps its file (gcloud 570.0.0, seen 2026-10-23).
- **gcloud's version**: the test that compares the login with gcloud's own runs the runner's gcloud, and a cloud session's VM may have another: `gcloud version` in a session tells.
- **A VM's pause**: no test pauses one.
  The login waits in `~/.local/state/gcloud-login/`, which a pause keeps by the [docs](https://code.claude.com/docs/en/cloud-environments)' word ("pauses with its files saved"), and the tests run `finish` with nothing of `start` left running, as after a pause.
  In a cloud session, `finish` succeeded 40 minutes after `start`, the VM having paused in between (seen 2026-10-29).

## gcloud's placeholder token

A cloud session's VM sets `CLOUDSDK_AUTH_ACCESS_TOKEN=proxy-injected`, a placeholder its proxy replaces with a token only when the environment has a GCP network secret (seen in October 2026).
gcloud uses it over the account it's logged in to, so `gcloud`, `bq` and `docker-credential-gcloud` send the placeholder and fail, and `gcloud auth print-access-token` prints it as if logged in.
Setting it to `""`, in a project's `settings.json` `env` or in the environment's variables, leaves the placeholder, and `CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE` doesn't take its place.
So `setup` unsets it on the first line of `~/.bashrc`, above the return that skips the rest in a non-interactive shell, as Claude's commands run; that also turns off the proxy's injection.
Remove it once the VM leaves the variable unset without a GCP secret: in a new session without the line, `[ -n "${CLOUDSDK_AUTH_ACCESS_TOKEN+x}" ] && echo set || echo unset` prints `unset`.
