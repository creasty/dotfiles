# Links the dotfiles into the home directory by where they are in the repository, not by a list:
#
#   home/<path>    ->  ~/.<path>          home/curlrc -> ~/.curlrc, home/aws/config -> ~/.aws/config
#   config/<path>  ->  ~/.config/<path>   config/git/config -> ~/.config/git/config
#
# The other modules add the few links that live elsewhere (dotfiles.link), e.g. nvim/ and the shell files.
# Links point into the checkout rather than the Nix store, so that edits apply without a rebuild. A new file
# needs `git add`, since flakes only see tracked files, and a switch.
{ username, dotfiles, ... }:
let
  root = ../..;
in
{
  home-manager.users.${username} =
    { config, lib, ... }:
    let
      # The tracked files under a directory of the repository, relative to it
      filesUnder =
        dir:
        let
          base = toString (root + "/${dir}");
        in
        map (path: lib.removePrefix "${base}/" (toString path)) (
          lib.filesystem.listFilesRecursive (root + "/${dir}")
        );

      # Keeps empty directories in git; nothing to link
      isPlaceholder =
        file:
        lib.elem (baseNameOf file) [
          ".keep"
          ".gitkeep"
        ];

      mirror =
        dir: target:
        lib.listToAttrs (
          map (file: lib.nameValuePair (target file) "${dir}/${file}") (
            lib.filter (file: !isPlaceholder file) (filesUnder dir)
          )
        );
    in
    {
      options.dotfiles.link = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Paths relative to the home directory, linked to paths relative to the dotfiles checkout.";
      };

      config = {
        dotfiles.link = mirror "home" (file: ".${file}") // mirror "config" (file: ".config/${file}");

        home.file = lib.mapAttrs (_: source: {
          source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${source}";
        }) config.dotfiles.link;

        # Ansible linked whole directories (e.g. ~/.config/git) and files straight into the checkout. Remove those
        # links first: home-manager would otherwise back up a file *through* a linked directory, i.e. rename it in
        # the repository.
        home.activation.unlinkAnsibleLinks = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
          for target in ${lib.escapeShellArgs (lib.attrNames config.dotfiles.link)}; do
            path="$HOME/$target"
            while [ "$path" != "$HOME" ]; do
              if [ -L "$path" ] && [[ "$(readlink "$path")" == ${lib.escapeShellArg dotfiles}/* ]]; then
                run rm $VERBOSE_ARG "$path"
              fi
              path="$(dirname "$path")"
            done
          done
        '';
      };
    };
}
