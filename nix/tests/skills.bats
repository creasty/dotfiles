#!/usr/bin/env bats
#
# The skills of nix/modules/skills.nix, linked at their pinned commits for Codex and Claude Code

load helper

@test "skills are linked at their pinned commits for Codex and Claude Code" {
  local skill folder problems=''
  for skill in $(manifest '.skills | keys | .[]'); do
    folder="$(manifest ".skills[\"$skill\"]")"
    [ "$(readlink -f "$HOME/.agents/skills/$skill")" = "$folder" ] &&
      [ "$(readlink -f "$HOME/.claude/skills/$skill")" = "$folder" ] &&
      [ -f "$HOME/.claude/skills/$skill/SKILL.md" ] || problems+="$skill"$'\n'
  done
  assert_none "$problems" 'not linked at the pinned commit'
}
