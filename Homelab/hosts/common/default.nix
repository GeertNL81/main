# /home/geert/nix/hosts/common/default.nix

{ config, pkgs, lib, ... }:

{
  ########################################################################
  # 1. Nix Flakes & Global Settings
  ########################################################################
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
  environment.systemPackages = [
    pkgs.neovim
    pkgs.vim
    pkgs.git
    pkgs.wget
    pkgs.btop
    pkgs.fastfetch
    pkgs.tailscale
    pkgs.nano
    pkgs.tmux
    pkgs.eza
    pkgs.bat
    pkgs.fd
    pkgs.duf
    pkgs.gping
    pkgs.zoxide
    # Removed pkgs.direnv from here as per request
  ];

  ########################################################################
  # 3. OpenSSH & Users
  ########################################################################
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin        = "no";
      PrintMotd = false;
    };
  };

  # Adding user-specific packages here AND FIXING USER DEFINITION
  users.users.geert = {
    isNormalUser = true; # <-- FIX: Set this to define the user type
    group        = "geert"; # <-- FIX: Set the primary group for the user
    extraGroups = [ "wheel" "tailscale" ];
    packages = [
      # Removed direnv from user-specific packages as per request
    ];
  };
  users.groups.geert = {}; # <-- FIX: Explicitly define the 'geert' group

  ########################################################################
  # 4. Tailscale fire-and-forget config
  ########################################################################
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  ########################################################################
  # 5. Firewall & Tailscale interface
  ########################################################################
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  ########################################################################
  # 6. Shell Customizations
  ########################################################################
  programs.bash = {
    interactiveShellInit = ''
      fastfetch
      eval "$(zoxide init bash)"
    '';
    shellAliases = {
      l = "eza -laT --icons";
    };
    completion.enable = true;
  };

  # --- Removed direnv enablement entirely as per request ---
  # programs.direnv = {
  #   enable = true;
  #   nix-direnv.enable = true;
  # };
}
