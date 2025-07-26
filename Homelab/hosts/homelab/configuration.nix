# /home/geert/nix/hosts/homelab/configuration.nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./containers.nix
    ./odoo-stack.nix
    ../common/default.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  boot.kernel.sysctl = lib.mkForce { "net.ipv4.ip_forward" = lib.mkForce 1; };

  networking = {
    hostName = "homelab";
    useDHCP = false;
    interfaces.enp5s0.ipv4.addresses = [ { address = "192.168.178.2"; prefixLength = 24; } ];
    defaultGateway = "192.168.178.1";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];

    firewall = {
      # Re-enable the firewall for security.
      enable = true; # <-- CHANGED THIS LINE BACK
      
      # Tell the firewall to trust the main LAN interface. This solves the
      # container networking issue while keeping the firewall active.
      # The 'tailscale0' interface is already trusted via common/default.nix.
      trustedInterfaces = [ "enp5s0" ]; # <-- ADDED THIS LINE
      
      # Keep the allowed ports for defense-in-depth.
      allowedTCPPorts = [ 5678 8200 8069 5432 ];
    };

    # The NAT block is correctly removed for this shared networking setup.
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
  systemd.services.tailscale-funnel = {
    description = "Tailscale Funnel for n8n (port 5678)";
    after = [ "network.target" "tailscaled.service" ];
    wants = [ "network.target" "tailscaled.service" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.tailscale}/bin/tailscale funnel http://127.0.0.1:5678";
      Restart = "always";
      RestartSec = 5;
    };
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
