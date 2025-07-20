{ pkgs
, stdenv
, writeShellScriptBin
, fetchurl
, lib
, ...
}:
let
  vhuit64 = stdenv.mkDerivation rec {
    name = "vhuit64";

    src = fetchurl {
      url = "https://www.virtualhere.com/sites/default/files/usbclient/${name}";
      hash = "sha256-J7k4kWvEX4GgQwXHA2SS62K/cjK+XYKriRzPH8XETvE=";
    };

    buildInputs = with pkgs; [ upx ];

    unpackPhase = "true";

    installPhase = ''
      mkdir -p $out/bin
      cp ${src} $out/bin/${name}
      chmod 0755 $out/bin/${name}
      upx -d $out/bin/${name}
    '';
  };

  NIX_LD_LIBRARY_PATH = with pkgs;
    lib.makeLibraryPath [
      cairo.out
      fontconfig.lib
      gdk-pixbuf.out
      glib.out
      gtk3.out
      libGL.out
      libgcc.lib
      libxkbcommon.out
      libz.out
      pango.out
      wayland-scanner.out
      xorg.libSM.out
      xorg.libX11.out
    ];
  NIX_LD = lib.fileContents "${stdenv.cc}/nix-support/dynamic-linker";
in
pkgs.writeShellScriptBin "virtualhere-client-gui" ''
  export NIX_LD_LIBRARY_PATH='${NIX_LD_LIBRARY_PATH}'${"\${NIX_LD_LIBRARY_PATH:+':'}$NIX_LD_LIBRARY_PATH"}
  export NIX_LD='${NIX_LD}'
  ${vhuit64}/bin/vhuit64 "$@"
''
