# ssh, with the keys in 1Password: its SSH agent signs in, so private keys don't live in ~/.ssh.
# ~/.ssh/keys keeps public keys, which a host's IdentityFile points at to pick the key (IdentitiesOnly).
# Host-specific configs stay out of the repository, in ~/.ssh/config.d.
{ username, ... }:
{
  home-manager.users.${username} =
    { lib, ... }:
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;

        includes = [ "config.d/*" ];

        settings."*" = {
          IdentityAgent = ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
          IdentitiesOnly = true;
          ServerAliveInterval = 30;
          TCPKeepAlive = true;
          # Trusts a host's key on the first connection (into ~/.ssh/known_hosts), and refuses the host once it changes
          StrictHostKeyChecking = "accept-new";
          LogLevel = "ERROR";
        };
      };

      home.activation.sshDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run install -d -m 700 $VERBOSE_ARG "$HOME/.ssh" "$HOME/.ssh/config.d" "$HOME/.ssh/keys"
      '';
    };
}
