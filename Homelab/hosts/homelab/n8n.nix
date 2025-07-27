{ config, lib, pkgs, ... }:

########################################################################
# n8n declarative container – uses flake’s own nixpkgs with allow-unfree
########################################################################
{
  containers.n8n-server = {
    autoStart      = true;
    privateNetwork = false;
    ephemeral      = false;

    bindMounts."/etc/resolv.conf" = {
      hostPath   = "/etc/resolv.conf";
      isReadOnly = true;
    };

    # container-level config – only this block is evaluated for the container
    config = { pkgs, ... }: {
      nixpkgs.config.allowUnfree = true;   # <— allow n8n

      system.stateVersion  = "24.11";
      networking.hostName  = "n8n-server";
      networking.firewall.enable = false;

      services.n8n = {
        enable  = true;
        settings = { port = 5678; host = "0.0.0.0"; };
      };
    };
  };
}
