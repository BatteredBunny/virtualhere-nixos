{
  pkgs,
  stdenv,
  fetchurl,
  lib,
  ...
}:
let
  version = "6.0.3";

  binaryName =
    {
      x86_64-linux = "vhuit64";
      aarch64-linux = "vhuitarm64";
    }
    .${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  sources = {
    vhuit64 = {
      url = "https://web.archive.org/web/20261011040340id_/https://www.virtualhere.com/sites/default/files/usbclient/vhuit64";
      hash = "sha256-8zl9pDpK13PL3TUGreSnYJRgUXnn6gKdJvlOkqvjvvE=";
    };
    vhuitarm64 = {
      url = "https://web.archive.org/web/20261001041334id_/https://www.virtualhere.com/sites/default/files/usbclient/vhuitarm64";
      hash = "sha256-nNZZ5Vhv/SX/mH6DcWXMDaVwhIqt1aKQfQDjMIm5164=";
    };
  };

  vhui = stdenv.mkDerivation rec {
    pname = "virtualhere-client-gui";
    inherit version;

    src = fetchurl sources.${binaryName};

    nativeBuildInputs = with pkgs; [ upx ];

    unpackPhase = "true";

    installPhase = ''
      mkdir -p $out/bin
      cp ${src} $out/bin/${binaryName}
      chmod 0755 $out/bin/${binaryName}
      upx -d $out/bin/${binaryName}
    '';

    doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
    nativeInstallCheckInputs = [ pkgs.versionCheckHook ];

    versionCheckProgramArg = "--help";
    versionCheckKeepEnvironment = [
      "out"
      "TMPDIR"
    ];

    # Will refuse to print help menu without this
    versionCheckProgram = pkgs.writeShellScript "virtualhere-client-gui-version" ''
      export HOME="$TMPDIR"
      exec ${lib.getExe pkgs.xvfb-run} -a ${stdenv.cc.bintools.dynamicLinker} \
        --library-path ${NIX_LD_LIBRARY_PATH} "$out/bin/${binaryName}" "$@"
    '';

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
      at-spi2-core
      cairo.out
      fontconfig.lib
      freetype
      gdk-pixbuf.out
      glib.out
      gtk3.out
      libGL.out
      wayland.out
      libgcc.lib
      libjpeg
      libxkbcommon.out
      libz.out
      pango.out

      libsm.out
      libx11.out
      libxtst
      libxxf86vm
    ];
in
(pkgs.writeShellScriptBin "virtualhere-client-gui" ''
  export NIX_LD_LIBRARY_PATH='${NIX_LD_LIBRARY_PATH}'${"\${NIX_LD_LIBRARY_PATH:+':'}$NIX_LD_LIBRARY_PATH"}
  exec ${vhui}/bin/${binaryName} "$@"
'').overrideAttrs
  {
    inherit version;
    passthru.updateScript = ./update.sh;
  }
