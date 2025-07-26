# /home/geert/nix/hosts/vm/odoo-stack.nix
#
# This file now ONLY defines the Odoo containers and their startup order.

{ config, pkgs, lib, ... }:

{
  ################################################################
  # PostgreSQL DB container
  ################################################################
  containers.odoo-db = {
    privateNetwork = true;
    hostAddress  = "10.233.3.1";
    localAddress = "10.233.3.2";

    bindMounts.postgres-data = {
      hostPath   = "/var/lib/postgresql-odoo";
      mountPoint = "/var/lib/postgresql";
      isReadOnly = false;
    };

    config = { ... }: {
      system.stateVersion = "25.05";
      services.postgresql = {
        enable        = true;
        package       = pkgs.postgresql_16;
        enableTCPIP   = true;
        initialScript = pkgs.writeText "odoo-init.sql" ''
          CREATE ROLE odoo WITH LOGIN PASSWORD 'GeertSilkens1981.';
          CREATE DATABASE odoo OWNER odoo;
        '';
        authentication = ''
          host all all 10.233.3.0/24 trust
        '';
      };
      users.users.postgres.isSystemUser = true;
    };
  };

  ################################################################
  #  Odoo application container – minimal, manual service
  ################################################################
  containers.odoo-app = {
    privateNetwork = true;
    hostAddress    = "10.233.3.1";
    localAddress   = "10.233.3.3";

    bindMounts.odoo-data = {
      hostPath   = "/var/lib/odoo-data";
      mountPoint = "/var/lib/odoo";
      isReadOnly = false;
    };

    config = { pkgs, ... }: {
      system.stateVersion = "25.05";
      
      # We no longer use services.odoo.enable, so we must add the package manually.
      environment.systemPackages = [ pkgs.odoo17 ];
      
      # Define the odoo user and group inside the container.
      users.groups.odoo = {};
      users.users.odoo = {
        isSystemUser = true;
        home         = "/var/lib/odoo";
        group        = "odoo";
      };

      # Manually define the systemd service for Odoo for full control.
      systemd.services.odoo = {
        description   = "Odoo ERP Stack (manual)";
        wantedBy      = [ "multi-user.target" ];
        after         = [ "network.target" ];
        serviceConfig = {
          User            = "odoo";
          Group           = "odoo";
          Restart         = "always";
          # StateDirectory creates and manages /var/lib/odoo with correct permissions
          StateDirectory  = "odoo";
          # WorkingDirectory ensures odoo runs in its data directory
          WorkingDirectory = "/var/lib/odoo";
          ExecStart =
            "${pkgs.odoo17}/bin/odoo"
            + " --config=/dev/null" # Ignore default config files
            + " --db_host 10.233.3.2"
            + " --db_port 5432"
            + " --db_user odoo"
            + " --db_password 'GeertSilkens1981.'"
            + " --xmlrpc-interface 0.0.0.0"
            + " --xmlrpc-port 8069"
            + " --without-demo=all";
        };
      };
    };
  };

  ################################################################
  # Host-level ordering
  ################################################################
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
