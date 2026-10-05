# Agent skills. `npx skills add -g` records what it installs in ~/.agents/.skill-lock.json, which is linked to
# home/agents/.skill-lock.json, and each skill's `ref` there pins the commit of its repository a switch installs it
# from; Renovate moves the commits. Pin a new skill as you add it, with `npx skills add <owner/repo>#<commit> -g`:
# `gh skill install` rewrites the lock without `ref`.
{
  lib,
  username,
  ...
}:
let
  lock = lib.importJSON ../../home/agents/.skill-lock.json;

  # The skill's directory in its repository at the pinned commit (github/gh-stack's skills/gh-stack), on its own: Codex
  # names a skill after the plugin of a manifest it finds above it (mattpocock/skills' .claude-plugin/plugin.json)
  folder =
    name: skill:
    if skill ? ref then
      builtins.path {
        path = "${
          builtins.fetchGit {
            url = skill.sourceUrl;
            rev = skill.ref;
            # (only that commit: some repositories carry large histories)
            shallow = true;
          }
        }/${dirOf skill.skillPath}";
        inherit name;
      }
    else
      throw "home/agents/.skill-lock.json: ${name} has no \"ref\", the commit of ${skill.sourceUrl} to install it from";

  folders = lib.mapAttrs folder lock.skills;
in
{
  home-manager.users.${username} =
    { lib, ... }:
    {
      # Each skill in ~/.agents/skills, where Codex reads it, as a link into the Nix store; ~/.claude/skills links to
      # it for Claude Code, as `npx skills add -g` lays them out. A link replaces whatever is there: a copy a CLI
      # installed, or the skill at another commit.
      home.activation.installSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        (
          link() {
            if [ "$(readlink "$2")" != "$1" ]; then
              run rm -rf "$2"
              run ln -s "$1" "$2"
            fi
          }
          run mkdir -p "$HOME/.agents/skills" "$HOME/.claude/skills"
          ${lib.concatStrings (
            lib.mapAttrsToList (name: folder: ''
              link ${lib.escapeShellArg folder} "$HOME/.agents/skills/"${lib.escapeShellArg name}
              link ../../.agents/skills/${lib.escapeShellArg name} "$HOME/.claude/skills/"${lib.escapeShellArg name}
            '') folders
          )}
        )
      '';
    };

  dotfiles.manifest.skills = folders;
}
