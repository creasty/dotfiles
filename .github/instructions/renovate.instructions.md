---
applyTo: "nvim/lazy-lock.json,flake.lock,config/mise/config.toml,nix/modules/skills.nix,nix/modules/shell.nix,.github/workflows/**"
---

# Reviewing a version bump

Changes to these files are mostly Renovate moving pins; README.md's Updates lists what each file pins and which tests cover it.
CI builds and tests the new versions, and the owner's machine runs them once merged. Review what CI can't tell:

- Read what changed upstream between the old and the new revision (the description links the comparison or the release notes), and find what this repository uses of it: options it passes to `setup()` in `nvim/lua/user/`, functions it calls, commands, keymaps, Nix options, CLI flags.
  Report a removal, rename, deprecation or change of behavior in any of them, and a changed default the owner would notice.
- CLAUDE.md describes workarounds for upstream bugs, each with the condition for removing it: report an update that meets the condition or breaks the workaround.
- Report a change beyond the pins, a major version, and an upstream repository that is archived or has moved.
- Don't report the pin itself, the lockfile's format, or that the new revision is untested.
