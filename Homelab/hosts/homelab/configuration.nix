# /home/geert/nix/hosts/homelab/configuration.nix
{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./hardware-configuration.nix # Your host's hardware specific configuration
      ./nspawn.nix                 # This defines 'baseline-nspawn'
      ./n8n.nix                    # This defines the 'n8n' container
      ./postgresql.nix             # <--- RE-ADDED THIS IMPORT
    ];

  nixpkgs.config.allowUnfree = true;
  virtualisation.containers.enable = true;
  networking.hostName = "homelab";
  system.stateVersion = "24.11";
  boot.loader.grub = { enable = true; devices = [ "/dev/disk/by-id/ata-SanDisk_SD9SN8W256G1002_184233800457" ]; };
  networking.useNetworkd = true;
  systemd.network.enable = true;
  networking.bridges."br-lan" = { interfaces = [ "enp5s0" ]; };
  networking.interfaces."br-lan" = { ipv4.addresses = [ { address = "192.168.178.2"; prefixLength = 24; } ]; };
  networking.defaultGateway = { address = "192.168.178.1"; interface = "br-lan"; };
  networking.nameservers = [ "8.8.8.8" ];
  services.openssh.enable = true;
  users.users.geert = { isNormalUser = true; extraGroups = [ "wheel" ]; initialPassword = "ResetRoot"; };

  environment.systemPackages = with pkgs; [
    neovim vim git wget btop fastfetch tailscale nano tmux eza bat fd duf gping zoxide curl
  ];

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  # Tailscale on the Host System (Automated Authentication & Subnet Routing)
  services.tailscale.enable = true;
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  systemd.services.tailscale-host-config = {
    description = "Tailscale Host Configuration (up, routes)";
    after = [ "tailscaled.service" ];
    requires = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.tailscale}/bin/tailscale up --authkey=${pkgs.lib.escapeShellArg "tskey-auth-ksqU5Ynzvh11CNTRL-rys7eCQ4j9jvpkJjvisFAjKUUuwMTeGCE"} --advertise-routes=192.168.178.0/24 --accept-routes";
      User = "root";
      Group = "root";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/nixos-containers/baseline-nspawn-data 0755 root root -"
    "d /var/lib/nixos-containers/n8n-data 0755 root root -"
    "d /var/lib/nixos-containers/postgresql-db-data/postgresql_data 0700 71 71 -" # <--- RE-ADDED THIS RULE
  ];
}
