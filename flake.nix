{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-alien-pkgs.url = "github:thiagokokada/nix-alien";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nix-alien-pkgs,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlays = [nix-alien-pkgs.overlays.default];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        vhuit64 = pkgs.stdenv.mkDerivation rec {
          name = "vhuit64";

          src = pkgs.fetchurl {
            url = "https://www.virtualhere.com/sites/default/files/usbclient/vhuit64";
            hash = "sha256-TjjycoyaHxQyNukTSNBHmwkXx5FAEnHyOJu4HgkN31I=";
          };

          buildInputs = with pkgs; [upx];

          unpackPhase = "true";

          installPhase = ''
            export HOME=$(mktemp -d)
            mkdir -p $out/bin

            cp ${src} vhuit64
            chmod 0755 vhuit64
            upx -d vhuit64
            cp vhuit64 $out/bin/vhuit64
          '';
        };

        virtualhere-client-gui = pkgs.writeShellScriptBin "virtualhere-client-gui" ''
          ${pkgs.nix-alien}/bin/nix-alien-ld ${vhuit64}/bin/vhuit64
        '';
      in
        with pkgs; {
          devShells.default = mkShell rec {
            buildInputs = [
              vhuit64
              virtualhere-client-gui
              nix-alien-ld
            ];
          };

          packages.default = virtualhere-client-gui;
        }
    );
}
