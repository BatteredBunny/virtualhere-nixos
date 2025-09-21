# Virtualhere-nixos

Virtualhere programs packaged for NixOS.

## Packages

- virtualhere-client-gui
- virtualhere-client-cli

[Client info](https://www.virtualhere.com/usb_client_software)

## Installing the flake

```nix
# flake.nix
inputs = {
    virtualhere.url = "github:BatteredBunny/virtualhere-nixos";
};
```

```nix
# configuration.nix
nixpkgs.overlays = [
    inputs.virtualhere.overlays.default
];

programs.nix-ld.enable = true;

boot.extraModulePackages = with config.boot.kernelPackages; [
    usbip
];
```