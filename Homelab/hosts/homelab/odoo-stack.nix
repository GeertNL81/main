# /home/geert/nix/hosts/homelab/odoo-stack.nix

{ config, pkgs, lib, ... }:

let
  odoo-pkg  = pkgs.odoo;
  masterPwd = "insecureBoot";   # CHANGE ME!

  pgInitSql = pkgs.writeText "pg-init.sql" ''
    CREATE DATABASE odoo OWNER odoo;
  '';
in
{
  services.postgresql = {
    enable     = true;
    package    = pkgs.postgresql_16;
    authentication = lib.mkAfter ''
      local all odoo  ident
    '';
    ensureUsers = [ { name = "odoo"; } ];
    initialScript = pgInitSql;
  };
  users.users.odoo = {
    isSystemUser = true;
    group        = "odoo";
    home         = "/var/lib/odoo";
    createHome   = true;
  };
  users.groups.odoo = { };
  systemd.services.odoo = {
    description = "Odoo ERP";
    wantedBy    = [ "multi-user.target" ];
    wants       = [ "postgresql.service" ];
    after       = [ "postgresql.service" "odoo-setupDb.service" ];
    serviceConfig = {
      Type             = "simple";
      User             = "odoo";
      WorkingDirectory = "/var/lib/odoo";
      ExecStart        = "${odoo-pkg}/bin/odoo -c /etc/odoo/odoo.conf";
      Restart          = "on-failure";
    };
  };
  environment.etc."odoo/odoo.conf".text = ''
    [options]
    db_host      = /run/postgresql
    db_port      = 5432
    db_user      = odoo
    db_password  =
    http_port    = 8069
    admin_passwd = ${masterPwd}
    log_level    = info
    addons_path  = ${odoo-pkg}/lib/python3.12/site-packages/odoo/addons
    data_dir     = /var/lib/odoo/.local/share/Odoo
  '';
  systemd.services.odoo-setupDb = {
    description = "Odoo initial DB bootstrap";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "postgresql.service" ];
    before      = [ "odoo.service" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      User            = "odoo";
    };
    path = with pkgs; [ postgresql odoo-pkg ];
    script = ''
      set -euo pipefail
      echo "Waiting for PostgreSQL socket ..."
      until pg_isready -q; do sleep 1; done
      tablesExist=$(psql -d odoo -tA -c \
        "SELECT to_regclass('public.ir_module_module') IS NULL::int")
      if [[ "$tablesExist" == "1" ]]; then
        echo "Installing base module..."
        odoo -c /etc/odoo/odoo.conf \
             -d odoo \
             -r odoo \
             -i base \
             --stop-after-init
      else
        echo "Database already has base module – skipping"
      fi
    '';
  };

  #############################################################################
  # Misc helpers
  #############################################################################
  # Packages are listed explicitly to ensure they merge correctly.
  environment.systemPackages = [
    pkgs.wkhtmltopdf
    pkgs.postgresql
    pkgs.xorg.libX11
  ];

  networking.firewall.allowedTCPPorts = [ 8069 ];
}
