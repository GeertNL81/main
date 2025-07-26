# /home/geert/nix/hosts/vm/containers.nix
#
# This file now ONLY defines the n8n container itself.

{ config, pkgs, lib, ... }:

{
  # --- n8n Automation Server Container ---
  containers."n8n-server" = {
    privateNetwork = true;
    hostAddress    = "10.233.1.1";
    localAddress   = "10.233.1.3";

    config = { pkgs, ... }: {
      system.stateVersion = "25.05";
      networking.firewall.allowedTCPPorts = [ 5678 ];
      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "n8n" ];
      users.groups.n8n = {};
      users.users.n8n = { isSystemUser = true; group = "n8n"; home = "/var/lib/n8n"; };
      systemd.services.n8n = {
        description   = "N8N automation server";
        wantedBy      = [ "multi-user.target" ];
        after         = [ "network.target" ];
        serviceConfig = {
          StateDirectory       = "n8n";
          StateDirectoryMode   = "0755";
          User                 = "n8n";
          Group                = "n8n";
          ExecStart            = "${pkgs.n8n}/bin/n8n";
          WorkingDirectory     = "/var/lib/n8n";
          Restart              = "always";
        };
        environment = {
          N8N_HOST            = "0.0.0.0";
          N8N_PORT            = "5678";
          WEBHOOK_URL         = "http://192.168.122.96:5678";
          N8N_SECURE_COOKIE   = "false";
        };
      };
    };
  };

  # --- Host-level Settings for the n8n Container ---
  systemd.services."container@n8n-server" = {
    after  = [ "network-online.target" ];
    wants  = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  };
}
