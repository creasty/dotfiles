# Agent skills. `skills add -g` (npx skills) and `gh skill install` record what they install in
# ~/.agents/.skill-lock.json, which is linked to home/agents/.skill-lock.json. A switch installs for Claude Code the
# skills it lists that ~/.claude/skills lacks, from their repositories' default branches: the lock doesn't pin them.
{
  lib,
  pkgs,
  username,
  ...
}:
let
  lock = lib.importJSON ../../home/agents/.skill-lock.json;

  # What `skills update -g` reinstalls a skill from: its repository and the skill's directory in it
  # (github/gh-stack/skills/gh-stack)
  sources = lib.mapAttrs (
    _: skill: lib.removeSuffix "/" "${skill.source}/${lib.removeSuffix "SKILL.md" skill.skillPath}"
  ) lock.skills;
in
{
  home-manager.users.${username} =
    { lib, ... }:
    {
      # The CLI writes its own lock to a scratch directory (XDG_STATE_HOME), leaving the checkout's as it is, and
      # reports no installs (DO_NOT_TRACK)
      home.activation.installSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        (
          export PATH=${lib.makeBinPath [ pkgs.git ]}:$PATH DO_NOT_TRACK=1
          XDG_STATE_HOME="$(mktemp -d)"
          export XDG_STATE_HOME
          trap 'rm -rf "$XDG_STATE_HOME"' EXIT
          ${lib.concatStrings (
            lib.mapAttrsToList (name: source: ''
              [ -e "$HOME"/.claude/skills/${lib.escapeShellArg name}/SKILL.md ] ||
                run ${lib.getExe pkgs.skills} add ${lib.escapeShellArg source} --skill ${lib.escapeShellArg name} -g -a claude-code -y
            '') sources
          )}
        )
      '';
    };

  dotfiles.manifest.skills = lib.attrNames lock.skills;
}
