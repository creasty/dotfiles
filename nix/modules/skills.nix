# Agent skills, linked for Claude Code (~/.claude/skills) and Codex (~/.agents/skills).
# Each repository is pinned at the commit (`rev`) of the tag or branch its `ref` names, which Renovate moves: a release
# for a repository that tags one of each change within weeks, its default branch for the others.
# `git ls-remote <url> <ref>` prints the commit, a tag's on the line ending in ^{} when there is one.
{ lib, username, ... }:
let
  repositories = [
    {
      url = "https://github.com/brycehamrick/editorial-skills";
      ref = "refs/heads/main";
      rev = "4043b9625b5751f5b8c65de6bf08ce6ce65ae88a";
      skills = lib.genAttrs [
        "editorial-context"
        "editorial-copy"
        "editorial-development"
        "editorial-line"
        "editorial-proof"
        "editorial-structural"
        "editorial-translation"
        "editorial-typesetting"
      ] (name: "skills/${name}");
    }
    {
      url = "https://github.com/coreyhaines31/marketingskills";
      ref = "refs/tags/v2.13.0";
      rev = "e85f3cbc2e4a79bf33b2a12e9bdd9087d414735b";
      skills.copy-editing = "skills/copy-editing";
    }
    {
      url = "https://github.com/github/gh-stack";
      ref = "refs/tags/v0.3.0";
      rev = "2a49e6751238633db504655d8a8eba3e433e827d";
      skills.gh-stack = "skills/gh-stack";
    }
    {
      url = "https://github.com/Leonxlnx/taste-skill";
      ref = "refs/heads/main";
      rev = "12af471f627f866411b4bd785b19646d3672784c";
      skills.design-taste-frontend = "skills/taste-skill";
    }
    {
      url = "https://github.com/mattpocock/skills";
      ref = "refs/tags/v1.3.1";
      rev = "24fe0ef7737efae15c87225755e9f6f5965e4888";
      skills = {
        grilling = "skills/productivity/grilling";
        handoff = "skills/productivity/handoff";
        writing-for-agents = "skills/productivity/writing-for-agents";
      };
    }
    {
      url = "https://github.com/nanaism/yomiyasu";
      ref = "refs/tags/v2.5.0";
      rev = "29d67ccb05e370b5958d72920a9cd1aa829dee80";
      skills.yomiyasu = "skills/yomiyasu";
    }
  ];

  # Each skill's directory in its repository, on its own: Codex names a skill after the plugin of a manifest it finds
  # above it (mattpocock/skills' .claude-plugin/plugin.json)
  skills = lib.mergeAttrsList (
    map (
      repository:
      let
        source = builtins.fetchGit {
          inherit (repository) url ref rev;
          # (only that commit: some repositories carry large histories)
          shallow = true;
        };
      in
      lib.mapAttrs (
        name: dir:
        builtins.path {
          path = "${source}/${dir}";
          inherit name;
        }
      ) repository.skills
    ) repositories
  );
in
{
  home-manager.users.${username}.home.file = lib.concatMapAttrs (name: folder: {
    ".agents/skills/${name}".source = folder;
    ".claude/skills/${name}".source = folder;
  }) skills;

  dotfiles.manifest.skills = skills;
}
