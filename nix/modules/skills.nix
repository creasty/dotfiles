# Agent skills, linked for Claude Code (~/.claude/skills) and Codex (~/.agents/skills), and this repository's own
# (skills/), linked straight into the checkout for Claude Code.
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
      ref = "refs/tags/v2.14.12";
      rev = "1f837447b20bb6f0e72d87b80ece1c221c362c7d";
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
      ref = "refs/tags/v2.5.1";
      rev = "f6b76575f949707b4e3c37cd86cb44b0b98643e8";
      skills.design-taste-frontend = "skills/taste-skill";
    }
    {
      url = "https://github.com/mattpocock/skills";
      ref = "refs/tags/v1.3.2";
      rev = "d1478fcb140db0b93c0c8df17bcfd311844749d0";
      skills = {
        grilling = "skills/productivity/grilling";
        handoff = "skills/productivity/handoff";
        writing-for-agents = "skills/productivity/writing-for-agents";
      };
    }
    {
      url = "https://github.com/nanaism/yomiyasu";
      ref = "refs/tags/v3.1.0";
      rev = "db78b9bc5e868549b517a037df7a4d1c93edac23";
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
  home-manager.users.${username} = {
    home.file = lib.concatMapAttrs (name: folder: {
      ".agents/skills/${name}".source = folder;
      ".claude/skills/${name}".source = folder;
    }) skills;

    # This repository's own skills, each folder in skills/, for Claude Code: they use the desktop app's tools
    dotfiles.link = lib.mapAttrs' (name: _: lib.nameValuePair ".claude/skills/${name}" "skills/${name}") (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../../skills)
    );
  };

  dotfiles.manifest.skills = skills;
}
