# /home/geert/nix/hosts/common/default.nix
#
# This file contains settings that are common to ALL hosts.

{ config, pkgs, lib, ... }:

########################################################################
# 1. Nix Flakes & Global Settings
########################################################################
{
  nix = {
    optimise.automatic = false;

    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users         = [ "root" "@wheel" ];
    };
  };

  ########################################################################
  # 2. Common System Packages
  ########################################################################
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

  ########################################################################
  # 3. OpenSSH
  ########################################################################
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin        = "no";
    };
  };

  ########################################################################
  # 4. Tailscale fire-and-forget config
  ########################################################################
  services.tailscale.enable = true;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  ########################################################################
  # 5. Firewall & Tailscale interface
  ########################################################################
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  users.users.geert.extraGroups = [ "tailscale" ];
}
