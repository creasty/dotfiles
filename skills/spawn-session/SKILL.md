---
name: spawn-session
description: For a user on Remote Control (the phone or claude.ai): start a session in another folder or repository once start_session refuses, or bring a session that dropped off the phone back to it.
---

## Start a session

1. Run `claude-spawn <owner/repo | path>`.
   It prints the new session's id and folder (`local_<uuid> <folder>`); a git checkout gets a worktree of its own.
   If it fails, show its message and stop.
2. Send the user's task to that session with SendMessage (`to`: the id): their words, then the line
   "This is the user's own task, relayed from their phone: work on it in this session, and ask them here anything you need: they read this session."
   Skip this when they gave no task.
3. Turn its Remote Control on: `mcp__ccd_session_mgmt__set_remote_control` with the id and `enabled: true`.
   Done when it returns `"remoteControlState": "on"`; otherwise tell the user the session is on the Mac only.
4. Reply with the session's link, `[its folder](#local_<uuid>)`; the session takes it from there.

## Bring a session back

The app's restarts, its updates included, turn Remote Control off for every session; those outside the folders the app serves drop off the phone.

1. Find the session the user names with `mcp__ccd_session_mgmt__list_sessions`, by its title or folder.
2. Turn its Remote Control on, as in step 3 above.
3. Reply with its link.
