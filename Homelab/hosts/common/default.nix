# /home/geert/nix/hosts/common/default.nix

{ config, pkgs, lib, ... }:

{
  # ... (Sections 1-5 remain the same) ...

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

  # Adding user-specific packages here
  users.users.geert = {
    extraGroups = [ "wheel" "tailscale" ]; # Added 'wheel' for sudo access if needed
    packages = with pkgs; [
      direnv # Installs direnv for the 'geert' user
    ];
  };

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

  # --- THIS IS THE ADDITION for direnv ---
  # Enable direnv to automatically load/unload environments
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # Crucial for integration with Nix
  };
}
