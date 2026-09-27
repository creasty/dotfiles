# tmux gives its panes the terminal type tmux-256color (config/tmux/tmux.conf). macOS's ncurses 5.7 has no entry for
# it, and can't read the one newer ncurses compiles, so macOS's own programs in panes (less, clear, /bin/zsh) wouldn't
# know the terminal: macOS's tic compiles one for them into ~/.terminfo.
{ pkgs, username, ... }:
let
  # The entry of nixpkgs' ncurses with fewer color pairs: ncurses 5.7 holds numbers in 16 bits, and its tic would
  # silently turn the 65536 pairs into 0
  terminfo = pkgs.runCommand "tmux-256color.terminfo" { } ''
    ${pkgs.ncurses}/bin/infocmp -x -A ${pkgs.ncurses}/share/terminfo tmux-256color \
      | sed 's/pairs#0x10000,/pairs#0x7fff,/' > $out
    grep -q 'pairs#0x7fff,' $out
  '';
in
{
  home-manager.users.${username} =
    { lib, ... }:
    {
      home.activation.tmuxTerminfo = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if ! /usr/bin/infocmp tmux-256color > /dev/null 2>&1; then
          run /usr/bin/tic -x -o "$HOME/.terminfo" ${terminfo}
        fi
      '';
    };
}
