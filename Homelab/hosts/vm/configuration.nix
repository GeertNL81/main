# /home/geert/nix/hosts/vm/default.nix
#
# This file contains the complete configuration for your 'vm' host.

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Includes the results of the hardware scan.
      ./hardware-configuration.nix
      ./containers.nix
      ./odoo-stack.nix
      ../common/default.nix
    ];

  # ... (bootloader is unchanged) ...
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.kernel.sysctl = lib.mkForce { "net.ipv4.ip_forward" = lib.mkForce 1; };

  networking = {
    hostName = "homelab";
    useDHCP = true;

    firewall = {
      enable = true;
      # MODIFIED: Removed "ve-odoo-app" as it no longer exists.
      trustedInterfaces = [ "ve-n8n-server" "tailscale0" ];
      allowedTCPPorts = [ 5678 8200 8069 ];
    };

    # MODIFIED: Removed the Odoo NAT rule.
    nat = {
      enable = true;
      externalInterface = "enp1s0";
      internalInterfaces = [ "lo" ];
      forwardPorts = [
        { sourcePort = 5678; destination = "10.233.1.3:5678"; } # n8n rule
      ];
    };
  };

  # ... (The rest of the file is unchanged) ...
  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";
  users.users.geert = { isNormalUser = true; description = "Geert"; extraGroups = [ "wheel" ]; };
  users.groups.duplicati = {};
  users.users.duplicati = { isSystemUser = true; group = "duplicati"; };
  users.groups.postgres = {};
  users.users.postgres = { isSystemUser = true; group = "postgres"; };
  users.groups.odoo = {};
  users.users.odoo = { isSystemUser = true; group = "odoo"; };
  systemd.tmpfiles.rules = [
    "d /var/lib/postgresql-odoo 0700 postgres postgres -"
    "d /var/lib/odoo-data 0750 odoo odoo -"
  ];
  environment.systemPackages = with pkgs; [ ];
  services.tailscale.enable = true;
  systemd.services.tailscale-funnel = {
    description = "Tailscale Funnel for n8n (port 5678)";
    after = [ "network-online.target" "tailscaled.service" ];
    wants = [ "network-online.target" "tailscaled.service" ];
    serviceConfig = { Type = "simple"; ExecStart = "${pkgs.tailscale}/bin/tailscale funnel http://127.0.0.1:5678"; Restart = "always"; RestartSec = 5; };
    wantedBy = [ "multi-user.target" ];
  };
  services.duplicati.enable = false;
  systemd.services.duplicati-server = {
    description = "Duplicati server";
    after    = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User  = "duplicati";
      Group = "duplicati";
      StateDirectory = "duplicati";
      StateDirectoryMode = "0750";
      WorkingDirectory = "/var/lib/duplicati";
      ExecStart = "${lib.getBin pkgs.duplicati}/bin/duplicati-server" + " --webservice-interface=any" + " --webservice-port=8200" + " --server-datafolder=/var/lib/duplicati" + " --webservice-allowed-hostnames=*";
      Restart = "always";
    };
  };
  system.stateVersion = "25.05";
}
