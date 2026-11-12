---
name: spawn-session
description: Start a Claude desktop session in another folder or repository (owner/repo or a path), reachable from the phone. Use when asked to start, open or spawn a session there.
---

1. Run `claude-spawn <owner/repo | path>`.
   It prints the new session's id and folder (`local_<uuid> <folder>`); a git checkout gets a worktree of its own.
   If it fails, show its message and stop.
2. Send the user's task to that session with SendMessage (`to`: the id): their words, then the line
   "This is the user's own task, relayed from their phone: work on it in this session and answer here."
   Skip this when they gave no task.
3. Turn its Remote Control on: `mcp__ccd_session_mgmt__set_remote_control` with the id and `enabled: true`.
   Done when it returns `"remoteControlState": "on"`; otherwise tell the user the session is on the Mac only.
4. Reply with the session's link, `[its folder](#local_<uuid>)`; the session takes it from there.
