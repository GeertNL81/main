# /home/geert/nix/hosts/homelab/n8n.nix
{ config, pkgs, lib, ... }:

{
  virtualisation.containers.enable = true;

  containers.n8n = {
    autoStart = true;
    extraFlags = [ "--network-bridge=br-lan" ];
    bindMounts = {
      "/var/lib/n8n" = {
        hostPath = "/var/lib/nixos-containers/n8n-data";
        isReadOnly = false;
      };
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
      networking.firewall.allowedTCPPorts = [ 80 22 5678 ];

      services.tailscale.enable = true;
      services.tailscale.extraDaemonFlags = [ "--tun=userspace-networking" ];

      users.users.geert = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        initialPassword = "ResetRoot";
      };

      users.users.n8n = {
        isSystemUser = true;
        group = "n8n";
        home = "/var/lib/n8n";
        createHome = true;
      };
      users.groups.n8n = { };

      environment.systemPackages = with pkgs; [
        neovim vim git wget btop fastfetch tailscale nano tmux eza bat fd duf gping zoxide curl
        nodejs_20 n8n iproute2
      ];

      systemd.services.tailscale-auth = {
        description = "Tailscale Authentication for n8n Container";
        after = [ "tailscaled.service" ];
        requires = [ "tailscaled.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          # CORRECTED: pkaks changed to pkgs
          ExecStart = "${pkgs.tailscale}/bin/tailscale up --authkey=${pkgs.lib.escapeShellArg "tskey-auth-ksqU5Ynzvh11CNTRL-rys7eCQ4j9jvpkJjvisFAjKUUuwMTeGCE"} --hostname=n8n"; # <--- TYPO FIXED HERE
          User = "root";
        };
      };

      systemd.services.n8n.serviceConfig.Environment = [
        "N8N_HOST=0.0.0.0" "N8N_PORT=5678" "N8N_PROTOCOL=http"
        "N8N_EDITOR_BASE_URL=http://192.168.178.208:5678/"
        "WEBHOOK_URL=http://192.168.178.208:5678/"
        "N8N_BASIC_AUTH_ACTIVE=true" "N8N_BASIC_AUTH_USER=geert"
        "N8N_BASIC_AUTH_PASSWORD=ResetRoot_N8N_Admin_Pass"
        "N8N_ENCRYPTION_KEY=ccF1VnXOplxMqQ1nN3yqeVcDH07qBMHHy1qp72KtcvI="
        "GENERIC_TIMEZONE=Europe/Amsterdam" "N8N_SECURE_COOKIE=false"
        "HOME=/var/lib/n8n" "N8N_DATA_FOLDER=/var/lib/n8n/.n8n"
      ];

      systemd.services.n8n = {
        description = "n8n Workflow Automation";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        requires = [ "network-online.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.n8n}/bin/n8n";
          Restart = "always";
          User = "n8n";
          Group = "n8n";
          StateDirectory = "n8n";
        };
      };
    };
  };
}
