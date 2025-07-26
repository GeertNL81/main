# /home/geert/nix/hosts/common/default.nix
#
# This file contains settings that are common to ALL hosts.

{ config, pkgs, lib, ... }:

{
  # --- Nix Flakes and Command Settings ---
  nix = {
    optimise.automatic = false;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "@wheel" ];
    };
  };

  # --- Common System Packages ---
  environment.systemPackages = with pkgs; [
    neovim
    vim
    git
    wget
    btop
    fastfetch
    tailscale
    nano
    tmux
    eza
  ];

  # --- Services ---
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # --- Tailscale Common Configuration (for all hosts) ---
  services.tailscale.enable = true;
  boot.kernel.sysctl = { "net.ipv4.ip_forward" = 1; };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  users.users.geert = {
    extraGroups = [ "tailscale" ];
  };
}
