#!/usr/bin/env bats
#
# The skills of ~/.agents/.skill-lock.json, installed at their pinned commits for Codex and Claude Code
# (nix/modules/skills.nix)

load helper

@test "locked skills are installed at their pinned commits for Codex and Claude Code" {
  local skill folder problems=''
  for skill in $(manifest '.skills | keys | .[]'); do
    folder="$(manifest ".skills[\"$skill\"]")"
    [ "$(readlink "$HOME/.agents/skills/$skill")" = "$folder" ] &&
      [ "$(readlink "$HOME/.claude/skills/$skill")" = "../../.agents/skills/$skill" ] &&
      [ -f "$HOME/.claude/skills/$skill/SKILL.md" ] || problems+="$skill"$'\n'
  done
  assert_none "$problems" 'not installed at the pinned commit'
}
