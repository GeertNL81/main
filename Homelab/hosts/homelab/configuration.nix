########################################################################
# hosts/homelab/configuration.nix – production-ready, single-host setup
########################################################################
{ config, pkgs, lib, ... }:
{
  ######################################################################
  # 1) Core idiomatic host imports
  ######################################################################
  imports = [
    ./hardware-configuration.nix
    ./odoo-stack.nix
    ../common/default.nix
  ];

  ######################################################################
  # 2) Static host-level facts
  ######################################################################
  networking.hostName = "homelab";

  networking.interfaces.enp5s0.ipv4.addresses = [
    { address = "192.168.178.2"; prefixLength = 24; }
  ];
  networking.defaultGateway = "192.168.178.1";
  networking.nameservers = [ "8.8.8.8" ];

  # Firewall – allow ports for nat-less container networking
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    5678   # n8n
    8069   # Odoo UI
    8200   # Duplicati UI
    5432   # PostgreSQL (debug only)
  ];

  ######################################################################
  # 3) GRUB 2 on legacy BIOS
  ######################################################################
  boot.loader.grub = {
    enable  = true;
    device  = "/dev/disk/by-id/ata-SanDisk_SD9SN8W256G1002_184233800457";
    # version 2;  ← removed because the option was deprecated
  };

  ######################################################################
  # 4) Tailscale and tools on the host
  ######################################################################
  services.tailscale.enable = true;
  environment.systemPackages = with pkgs; [ tailscale ];

  ######################################################################
  # 5) Local user accounts
  ######################################################################
  users.users.geert  = {
    isNormalUser = true;
    group        = "geert";
    extraGroups  = [ "wheel" ];
    shell        = pkgs.bash;
  };
  users.groups.geert = {};

  # NEW: runtime account for duplicati-server.service
  users.users.duplicati = {
    isSystemUser = true;
    description  = "Duplicati runtime user";
    group        = "duplicati";
    home         = "/var/lib/duplicati";
    createHome   = true;
  };
  users.groups.duplicati = {};

  ######################################################################
  # 6) Duplicati containerised via a dedicated systemd service
  ######################################################################
  systemd.services.duplicati-server = {
    description   = "Duplicati backup server on host port 8200";
    wantedBy      = [ "multi-user.target" ];
    serviceConfig = {
      Type            = "simple";
      User            = "duplicati";
      Group           = "duplicati";
      WorkingDirectory= "/tmp";
      StateDirectory  = "duplicati";
      ExecStart       = "${pkgs.duplicati}/bin/duplicati-server \
                         --webservice-port=8200 \
                         --webservice-interface=0.0.0.0";
      Restart         = "on-failure";
      TimeoutStartSec = "20s";
    };
  };

  system.stateVersion = "24.11";
}
