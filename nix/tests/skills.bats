#!/usr/bin/env bats
#
# The skills of ~/.agents/.skill-lock.json, installed for Claude Code (nix/modules/skills.nix)

load helper

@test "locked skills are installed for Claude Code" {
  local skill problems=''
  for skill in $(manifest '.skills[]'); do
    [ -f "$HOME/.claude/skills/$skill/SKILL.md" ] || problems+="$skill"$'\n'
  done
  assert_none "$problems" 'not installed'
}
