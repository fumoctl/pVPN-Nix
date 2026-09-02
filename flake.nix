{
  description = "Nix flake for pVPN (unofficial Proton VPN client)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      linuxSystems = nixpkgs.lib.filter (nixpkgs.lib.hasSuffix "-linux") nixpkgs.lib.systems.flakeExposed;
      forAllSystems = nixpkgs.lib.genAttrs linuxSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          pvpn = pkgs.callPackage ./pkgs/pvpn.nix { };
          default = self.packages.${system}.pvpn;
        }
      );

      overlays = {
        pvpn = import ./overlay.nix;
        default = self.overlays.pvpn;
      };

      nixosModules = {
        pvpn = import ./modules/nixos/pvpn.nix;
        default = self.nixosModules.pvpn;
      };

      apps = forAllSystems (
        system: rec {
          pvpn = {
            type = "app";
            program = "${self.packages.${system}.pvpn}/bin/pvpn";
            meta.description = "pVPN TUI client";
          };
          pvpnctl = {
            type = "app";
            program = "${self.packages.${system}.pvpn}/bin/pvpnctl";
            meta.description = "pVPN CLI controller";
          };
          pvpnd = {
            type = "app";
            program = "${self.packages.${system}.pvpn}/bin/pvpnd";
            meta.description = "pVPN daemon";
          };
          default = pvpn;
        }
      );

      formatter = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.nixfmt or pkgs.nixpkgs-fmt
      );
    };
}
