# Virtualhere-nixos

Virtualhere programs packaged for NixOS.

## Packages

- virtualhere-client-gui
- virtualhere-client-cli

[Virtualhere usage](https://www.virtualhere.com/usb_client_software)

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

## Running packages from flake

Must be ran with raised privileges!

```bash
nix shell github:BatteredBunny/virtualhere-nixos#virtualhere-client-gui
sudo -E virtualhere-client-gui
```