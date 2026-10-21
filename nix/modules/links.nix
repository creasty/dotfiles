# Links the dotfiles into the home directory by where they are in the repository, not by a list:
#
#   home/<path>    ->  ~/.<path>          home/curlrc -> ~/.curlrc, home/aws/config -> ~/.aws/config
#   config/<path>  ->  ~/.config/<path>   config/git/config -> ~/.config/git/config
#
# The other modules add the few links that live elsewhere (dotfiles.link), e.g. nvim/ and the shell files.
# Links point straight into the checkout, so that edits apply without a rebuild, and so that they resolve before /nix
# is mounted: the apps macOS starts at login (windows it reopens, login items) read their configs a few seconds
# before. home-manager's links (home.file) go through the Nix store, so the activation makes these itself.
# A new file needs `git add`, since flakes only see tracked files, and a switch.
# A file already in a link's place is moved aside with the suffix of backupFileExtension (default.nix), unless it's
# identical to the one linked.
{ username, dotfiles, ... }:
let
  root = ../..;
in
{
  home-manager.users.${username} =
    {
      config,
      lib,
      pkgs,
      ...
    }:
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

      # A line per link: the path relative to the home directory, a tab, and the path it links to
      links = pkgs.writeText "dotfiles-links" (
        lib.concatStrings (
          lib.mapAttrsToList (target: source: "${target}\t${dotfiles}/${source}\n") config.dotfiles.link
        )
      );

      # The links the last switch made, for the next one to remove those that are gone
      made = lib.escapeShellArg "${config.xdg.stateHome}/dotfiles/links";
    in
    {
      options.dotfiles.link = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Paths relative to the home directory, linked to paths relative to the dotfiles checkout.";
      };

      config = {
        dotfiles.link = mirror "home" (file: ".${file}") // mirror "config" (file: ".config/${file}");

        # After home-manager's links, so that a path moving from home.file to here is first removed by home-manager
        home.activation.linkDotfiles = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          (
            cd "$HOME"
            if [[ -f ${made} ]]; then
              targets=$'\n'"$(cut -f 1 ${links})"$'\n'
              while IFS=$'\t' read -r target source; do
                [[ $targets == *$'\n'"$target"$'\n'* ]] && continue
                # Only a link this made: anything else in its place since is left alone
                [[ "$(readlink "$target")" == "$source" ]] || continue
                run rm "$target"
                [[ "$(dirname "$target")" == . ]] || run rmdir -p --ignore-fail-on-non-empty "$(dirname "$target")"
              done < ${made}
            fi

            while IFS=$'\t' read -r target source; do
              if [[ -e "$target" && ! -L "$target" ]]; then
                if [[ -f "$target" ]] && cmp -s "$source" "$target"; then
                  run rm "$target"
                elif [[ -e "$target.$HOME_MANAGER_BACKUP_EXT" ]]; then
                  errorEcho "~/$target is in the way of a link to $source, and ~/$target.$HOME_MANAGER_BACKUP_EXT exists"
                  exit 1
                else
                  run mv "$target" "$target.$HOME_MANAGER_BACKUP_EXT"
                fi
              fi
              if [[ "$(readlink "$target")" != "$source" ]]; then
                run mkdir -p "$(dirname "$target")"
                run ln -Tsf "$source" "$target"
              fi
            done < ${links}

            run install -D -m 644 ${links} ${made}
          )
        '';
      };
    };
}
