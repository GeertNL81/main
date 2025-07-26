# /home/geert/nix/hosts/homelab/odoo-stack.nix
{ config, pkgs, lib, ... }:
{
  # The postgres user must exist on the HOST for the activation script.
  users.users.postgres.isSystemUser = true;

  # This activation script guarantees the directory exists before services start.
  system.activationScripts.postgresqlOdooDir = lib.mkForce ''
    install -d -m 0700 -o postgres -g postgres /var/lib/postgresql-odoo
  '';

  # This tmpfiles rule maintains the directory's state across boots.
  systemd.tmpfiles.rules = [
    "Z /var/lib/postgresql-odoo - postgres postgres - -"
  ];

  containers.odoo-db = {
    privateNetwork = false;
    bindMounts.postgres-data = { hostPath = "/var/lib/postgresql-odoo"; mountPoint = "/var/lib/postgresql"; isReadOnly = false; };
    config = { pkgs, ... }:
      let
        # THE FIX: Inside writeShellScript, the shell sees the string directly.
        # It requires standard shell quoting, not Nix quote escaping.
        initScript = pkgs.writeShellScript "setup-odoo-db.sh" ''
          set -euo pipefail
          echo "Checking if Odoo database role needs creation..."
          if ! ${pkgs.postgresql_16}/bin/psql -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='odoo'" | grep -q 1; then
            echo "--- Role 'odoo' not found. Creating role and database. ---"
            # The SQL string now uses plain single quotes, which is correct for the shell.
            ${pkgs.postgresql_16}/bin/psql -v ON_ERROR_STOP=1 --username postgres -d postgres -c "CREATE ROLE odoo WITH LOGIN PASSWORD 'GeertSilkens1981';"
            ${pkgs.postgresql_16}/bin/psql -v ON_ERROR_STOP=1 --username postgres -d postgres -c "CREATE DATABASE odoo OWNER odoo;"
          else
            echo "--- Role 'odoo' already exists. Skipping setup. ---"
          fi
        '';
      in
      {
        system.stateVersion = "25.05";

        services.postgresql = {
          enable = true;
          package = pkgs.postgresql_16;
          enableTCPIP = true;
          dataDir = "/var/lib/postgresql";
        };

        systemd.services.init-odoo-db = {
          description = "Initialize Odoo database and role";
          after = [ "postgresql.service" ];
          requires = [ "postgresql.service" ];
          wantedBy = [ "multi-user.target" ];
          
          serviceConfig = {
            Type = "oneshot";
            User = "postgres";
            ExecStart = "${initScript}";
          };
        };
      };
  };

  containers.odoo-app = {
    # Odoo app configuration is correct and remains unchanged
    privateNetwork = false;
    bindMounts.odoo-data = { hostPath = "/var/lib/odoo-data"; mountPoint = "/var/lib/odoo"; isReadOnly = false; };
    config = { pkgs, ... }: {
      system.stateVersion = "25.05";
      environment.systemPackages = [ pkgs.odoo17 ];
      users.groups.odoo = {};
      users.users.odoo = { isSystemUser = true; home = "/var/lib/odoo"; group = "odoo"; };
      systemd.services.odoo = {
        description = "Odoo ERP Stack (manual)";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          User = "odoo";
          Group = "odoo";
          Restart = "always";
          StateDirectory = "odoo";
          WorkingDirectory = "/var/lib/odoo";
          ExecStart = "${pkgs.odoo17}/bin/odoo"
            + " --config=/dev/null"
            + " --db_host 127.0.0.1"
            + " --db_port 5432"
            + " --db_user odoo"
            + " --db_password 'GeertSilkens1981'"
            + " --xmlrpc-interface 0.0.0.0"
            + " --xmlrpc-port 8069"
            + " --without-demo=all";
        };
      };
    };
  };

  # Standard service dependencies are now correct.
  systemd.services."container@odoo-db" = {
    after       = [ "network-online.target" ];
    wants       = [ "network-online.target" ];
    wantedBy    = [ "multi-user.target" ];
  };
  systemd.services."container@odoo-app" = {
    after       = [ "container@odoo-db.service" ];
    wants       = [ "container@odoo-db.service" ];
    wantedBy    = [ "multi-user.target" ];
  };
}
