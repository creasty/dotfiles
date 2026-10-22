# This Mac

- It's shared: several sessions and worktrees run at once.
  Stop only what you started, through its handle (TaskStop, preview_stop) or a PID you captured, never by name, pattern or port; when a port is taken, use another.
  Stop your servers when you're done unless I'm looking at them.
- Never load it to make a race or a flaky test show up (CPU-hogging processes, parallel loops of a test): run such a load on CI, or in an isolated Docker container capped with `--cpus` and `--memory`.
- I work in the desktop app, locally and in the cloud: push before handing work to a cloud session.
- Sibling repositories are at `~/go/src/github.com/<owner>/<repo>`.

## Memory

- A lesson that holds in every repository and changes your default belongs in `~/.claude/CLAUDE.md`, or here when it holds only on this Mac: propose it rather than saving it to one project's memory.
