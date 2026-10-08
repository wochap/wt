{
  description = "wt: git worktree manager";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
