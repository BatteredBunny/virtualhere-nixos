{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      systems = lib.systems.flakeExposed;

      forAllSystems = lib.genAttrs systems;

      nixpkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
        }
      );
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              usbutils
              nixpkgs-fmt
            ];
          };
        }
      );

      overlays.default = final: prev: {
        virtualhere-client-gui = final.callPackage ./pkgs/virtualhere-client-gui { };
        virtualhere-client-cli = final.callPackage ./pkgs/virtualhere-client-cli { };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        lib.makeScope pkgs.newScope (final: self.overlays.default final pkgs)
      );
    };
}
