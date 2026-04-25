{
  pkgs,
  stdenv,
  fetchurl,
  lib,
  ...
}:
let
  binaryName =
    {
      x86_64-linux = "vhuit64";
      aarch64-linux = "vhuitarm64";
    }
    .${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  sources = {
    vhuit64 = {
      url = "https://web.archive.org/web/20260423003850id_/https://www.virtualhere.com/sites/default/files/usbclient/vhuit64";
      hash = "sha256-5WirVHTZn5UfYq+BF9vvf9Li1K0OdeK6tgyWU1uVaAE=";
    };
    vhuitarm64 = {
      url = "https://web.archive.org/web/20260425003847id_/https://www.virtualhere.com/sites/default/files/usbclient/vhuitarm64";
      hash = "sha256-o1u0+691sUOLwZy8Qso04pUhZwFAMDm00n+DiQ1ZJ5M=";
    };
  };

  vhui = stdenv.mkDerivation rec {
    pname = "virtualhere-client-gui";
    version = "unstable-2026-04-25";

    src = fetchurl sources.${binaryName};

    buildInputs = with pkgs; [ upx ];

    unpackPhase = "true";

    installPhase = ''
      mkdir -p $out/bin
      cp ${src} $out/bin/${binaryName}
      chmod 0755 $out/bin/${binaryName}
      upx -d $out/bin/${binaryName}
    '';

    passthru.updateScript = ./update.sh;

    meta = {
      description = "VirtualHere USB client GUI";
      homepage = "https://www.virtualhere.com/usb_client_software";
      license = lib.licenses.unfree;
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
  };

  NIX_LD_LIBRARY_PATH =
    with pkgs;
    lib.makeLibraryPath [
      cairo.out
      fontconfig.lib
      gdk-pixbuf.out
      glib.out
      gtk3.out
      libGL.out
      wayland.out
      libgcc.lib
      libxkbcommon.out
      libz.out
      pango.out
      wayland-scanner.out

      # TODO: Refactor when nixos 25.11 gets deprecated
      xorg.libSM.out
      xorg.libX11.out
    ];
in
pkgs.writeShellScriptBin "virtualhere-client-gui" ''
  export NIX_LD_LIBRARY_PATH='${NIX_LD_LIBRARY_PATH}'${"\${NIX_LD_LIBRARY_PATH:+':'}$NIX_LD_LIBRARY_PATH"}
  exec ${vhui}/bin/${binaryName} "$@"
''
