# /home/geert/nix/hosts/homelab/nspawn.nix
{ config, pkgs, lib, ... }:

{
  virtualisation.containers.enable = true;

  containers.baseline-nspawn = {
    autoStart = true;
    # IMPORTANT: Revert extraFlags to only essential networking.
    # Capabilities and bind-device are NOT needed for userspace networking.
    extraFlags = [ "--network-bridge=br-lan" ]; # <--- ENSURE THIS IS THE ONLY CONTENT HERE
    bindMounts."/var/containerdata" = {
      hostPath = "/var/lib/nixos-containers/baseline-nspawn-data";
      isReadOnly = false;
    };

    config = {
      system.stateVersion = "24.11";
      systemd.network.enable = true;
      systemd.network.networks."10-eth0-dhcp.network" = {
        matchConfig.Name = "eth0";
        networkConfig = { DHCP = "ipv4"; };
      };
      networking.useHostResolvConf = false;
      services.openssh.enable = true;
      networking.firewall.allowedTCPPorts = [ 80 22 ];

      # ADDED: services.tailscale for this container
      services.tailscale.enable = true;
      # CRUCIAL: Enable userspace networking for Tailscale inside the container
      services.tailscale.extraDaemonFlags = [ "--tun=userspace-networking" ]; # <--- ADD THIS LINE

      users.users.geert = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        initialPassword = "ResetRoot";
      };

      services.httpd.enable = true;
      services.httpd.virtualHosts."localhost" = {
        documentRoot = "/var/www";
      };

      # NEW SERVICE: tailscale-auth for automatic login
      systemd.services.tailscale-auth = { # <--- ADD THIS NEW SERVICE
        description = "Tailscale Authentication for baseline-nspawn Container";
        after = [ "tailscaled.service" ]; # Ensure daemon is up
        requires = [ "tailscaled.service" ]; # Hard dependency
        wantedBy = [ "multi-user.target" ]; # Start at boot
        serviceConfig = {
          Type = "oneshot"; # Runs once and exits
          RemainAfterExit = true; # Stays 'active' after completion
          # Use your authkey to automatically log in.
          # Hostname for this container will be 'baseline-nspawn'
          ExecStart = "${pkgs.tailscale}/bin/tailscale up --authkey=${pkgs.lib.escapeShellArg "tskey-auth-ksqU5Ynzvh11CNTRL-rys7eCQ4j9jvpkJjvisFAjKUUuwMTeGCE"} --hostname=baseline-nspawn";
          User = "root"; # tailscale up typically needs root
        };
      };

      # UPDATED: Common utility packages (ensure tailscale is here)
      environment.systemPackages = with pkgs; [
        neovim
        vim
        git
        wget
        btop
        fastfetch
        tailscale # <--- Ensure tailscale is here
        nano
        tmux
        eza
        bat
        fd
        duf
        gping
        zoxide
        curl
      ];
    };
  };
}
