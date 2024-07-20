{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-alien-pkgs.url = "github:thiagokokada/nix-alien";
  };

  outputs =
    { nixpkgs
    , flake-utils
    , nix-alien-pkgs
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ nix-alien-pkgs.overlays.default ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        virtualhere-client-gui = pkgs.callPackage ./gui.nix { };
        virtualhere-client-cli = pkgs.callPackage ./cli.nix { };
      in
      with pkgs; {
        devShells.default = mkShell {
          buildInputs = [
            virtualhere-client-gui
            virtualhere-client-cli

            usbutils
          ];
        };

        packages = {
          default = virtualhere-client-gui;
          gui = virtualhere-client-gui;
          cli = virtualhere-client-cli;
        };
      }
    );
}
