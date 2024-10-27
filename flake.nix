{
  description = "Homelab";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = inputs@{ self, ... }:
    let
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      buildDeps = with pkgs; [ fluxcd kubectl k9s kind ];
    in {
      nixosConfigurations.vm = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./vm.nix
          "${inputs.nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
        ];
      };

      devShells.${system}.default = pkgs.mkShell { buildInputs = buildDeps; };
    };
}
