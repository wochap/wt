{
  description = "wt: git worktree manager";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/1f607aa79b6356ed45d3cd3c8079c196e79efa2c"; # nixos-26.05 (26 oct 2026)
  inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let wt = nixpkgs.legacyPackages.${system}.callPackage ./nix/package.nix { };
        in { inherit wt; default = wt; });

      overlays.default = final: prev: {
        wt = final.callPackage ./nix/package.nix { };
      };

      homeManagerModules.wt = import ./nix/hm-module.nix { inherit self; };
      homeManagerModules.default = self.homeManagerModules.wt;

      checks = forAllSystems (system:
        import ./nix/checks.nix {
          inherit self home-manager;
          pkgs = nixpkgs.legacyPackages.${system};
        });
    };
}
