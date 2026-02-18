{
  description = "Flutter development environment";

  nixConfig = {
    permittedInsecurePackages = [ "olm-3.2.16" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = { self, nixpkgs, flake-utils, treefmt-nix, }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # pkgs = nixpkgs.legacyPackages.${system};
        pkgs = import nixpkgs {
          inherit system;
          config = { permittedInsecurePackages = [ "olm-3.2.16" ]; };
        };
        pkgsFor = nixpkgs.legacyPackages;

        treefmtEval = treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.alejandra.enable = true;
          programs.dart-format.enable = true;
          programs.yamlfmt.enable = true;
          programs.yamlfmt.excludes = [ "pubspec.lock" ];
        };
      in {
        # packages.default = pkgsFor.${system}.callPackage ./. { }; 

        devShells.default = import ./shell.nix { inherit pkgs; };

        formatter = treefmtEval.config.build.wrapper;

        checks.formatting = treefmtEval.config.build.check self;
      });
}
