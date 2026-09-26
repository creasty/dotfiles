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

        # `*` comes last, after the other hosts
        settings = {
          "va_* 192.168.33.*" = {
            User = "vagrant";
            IdentityFile = "~/.vagrant.d/insecure_private_key";
          };

          "*" = {
            IdentityAgent = ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
            IdentitiesOnly = true;
            ServerAliveInterval = 30;
            TCPKeepAlive = true;
            StrictHostKeyChecking = false;
            UserKnownHostsFile = "/dev/null";
            LogLevel = "ERROR";
          };
        };
      };

      home.activation.sshDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run install -d -m 700 $VERBOSE_ARG "$HOME/.ssh" "$HOME/.ssh/config.d" "$HOME/.ssh/keys"
        # Copies of the common config that Ansible assembled ~/.ssh/config from, now part of the config itself
        run rm -f $VERBOSE_ARG "$HOME/.ssh/config.d/_common" "$HOME/.ssh/config.d/_va"
      '';
    };
}
