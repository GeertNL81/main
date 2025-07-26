# /home/geert/nix/hosts/homelab/containers.nix
{ config, pkgs, lib, ... }:
{
  containers."n8n-server" = {
    privateNetwork = true; # <-- REVERTED
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
          WEBHOOK_URL         = "http://192.168.178.2:5678";
          N8N_SECURE_COOKIE   = "false";
        };
      };
    };
  };
  systemd.services."container@n8n-server" = {
    after  = [ "network.target" ];
    wants  = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };
}
