{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-alien-pkgs.url = "github:thiagokokada/nix-alien";
  };

  outputs =
    { self
    , nixpkgs
    , nix-alien-pkgs
    , ...
    }:
    let
      inherit (nixpkgs) lib;

      systems = lib.systems.flakeExposed;

      forAllSystems = lib.genAttrs systems;

      overlays = [ nix-alien-pkgs.overlays.default ];
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system overlays;
      });
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs;
              [
                usbutils
                nixpkgs-fmt
              ] ++ lib.optionals pkgs.stdenv.isLinux [
                nix-alien
              ];
          };
        });

      overlays.default = final: prev: {
        virtualhere-client-gui = final.callPackage ./pkgs/gui-client.nix { };
        virtualhere-client-cli = final.callPackage ./pkgs/cli-client.nix { };
      };

      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        lib.makeScope pkgs.newScope (final: self.overlays.default final pkgs)
      );
    };
}
