# /home/geert/nix/flake.nix
#
# This is the main entry point for your entire NixOS configuration.

{
  description = "Geert's NixOS Configurations";

  # --- INPUTS ---
  # These are the external dependencies of your configuration.
  inputs = {
    # The NixOS package collection. We track the 'nixos-unstable' branch.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-odoo.url = "github:NixOS/nixpkgs/nixos-unstable";

    # You could add other inputs here later, like home-manager.
    # home-manager.url = "github:nix-community/home-manager";
    # home-manager.inputs.nixpkgs.follows = "nixpkgs";
   };

  # --- OUTPUTS ---
  # These are the things your flake can build, like your NixOS systems.
  outputs = { self, nixpkgs, ... }@inputs: {

    # This is where we define the NixOS systems that can be built.
    nixosConfigurations = {

      # The one, true definition for your bare-metal server.
      homelab = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/homelab/configuration.nix
        ];
      };

      # If you want to keep a VM config, it MUST have a different name, e.g.:
      # vm = nixpkgs.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   specialArgs = { inherit inputs; };
      #   modules = [
      #     ./hosts/vm/configuration.nix
      #   ];
      # };

    };
  };
}
