# PostgreSQL's commands, and a server of this machine's own, which `pg_ctl start` starts and `pg_ctl stop` stops
{ pkgs, username, ... }:
let
  postgresql = pkgs.postgresql_18;

  env = {
    # The server's data, for initdb, pg_ctl and postgres: a directory per major version, which no other major version
    # opens
    PGDATA = "$HOME/.local/share/postgres/${postgresql.psqlSchema}";
    # The user psql, createdb and apps connect as when they name none
    PGUSER = "postgres";
  };
in
{
  environment.variables = env;

  home-manager.users.${username} =
    { lib, ... }:
    {
      # psql and pg_dump, which nixpkgs has only with the server
      home.packages = [ postgresql ];

      # On the first switch: the superuser postgres, no password for connections from this machine, and every
      # statement logged to $PGDATA/log/server.log. initdb runs with the settings too, so it prints its own statements.
      home.activation.initPostgresql = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -e "${env.PGDATA}/PG_VERSION" ]; then
          run ${postgresql}/bin/initdb --pgdata="${env.PGDATA}" --username=${env.PGUSER} --auth=trust --no-instructions \
            -c logging_collector=on -c log_filename=server.log -c log_statement=all
        fi
      '';
    };
}
