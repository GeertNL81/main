########################################################################
# flake.nix – homelab NixOS 24.11 (x86_64-linux) – n8n + Odoo 17 stack
########################################################################
{
  description = "Single-host NixOS server running n8n and Odoo";

  inputs = {
    # Long-term-support branch with guaranteed binary cache
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }@inputs:
  let
    system = "x86_64-linux";
  in
  {
    nixosConfigurations.homelab = nixpkgs.lib.nixosSystem {
      inherit system;

      modules = [
        # Base hardware identification (generated on-install)
        ./hosts/homelab/hardware-configuration.nix

        # Declared services & containers (Odoo + PostgreSQL)
        ./hosts/homelab/odoo-stack.nix

        # Rest of host-level configuration
        ./hosts/homelab/configuration.nix
      ];

      # Our flake already contains the channel, no extra logic here
    };

    # Convenience: build the toplevel without needing to activate
    packages.${system} = {
      homelab = self.nixosConfigurations.homelab.config.system.build.toplevel;
      default = self.packages.${system}.homelab;
    };

    # Auto-formatter hook for CI / editor integration
    formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
  };
}
