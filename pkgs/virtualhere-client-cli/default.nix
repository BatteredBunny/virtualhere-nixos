{
  stdenv,
  fetchurl,
  lib,
  ...
}:
let
  binaryName =
    {
      x86_64-linux = "vhclientx86_64";
      aarch64-linux = "vhclientarm64";
    }
    .${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  sources = {
    vhclientx86_64 = {
      url = "https://web.archive.org/web/20260614005452id_/https://www.virtualhere.com/sites/default/files/usbclient/vhclientx86_64";
      hash = "sha256-OB0v9A9/O++J3f3q4BsYbg0BHV9jYZgBQ8qP20meWXA=";
    };
    vhclientarm64 = {
      url = "https://web.archive.org/web/20260614005559id_/https://www.virtualhere.com/sites/default/files/usbclient/vhclientarm64";
      hash = "sha256-1OlkjTsN3d/ct80ant3zaA0+/qdY9oGsqJIPkbkrDk4=";
    };
  };
in
stdenv.mkDerivation rec {
  pname = "virtualhere-client-cli";
  version = "unstable-2026-06-14";

  src = fetchurl sources.${binaryName};

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/${binaryName}
    chmod 0755 $out/bin/${binaryName}
    ln -s $out/bin/${binaryName} $out/bin/virtualhere-client-cli
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "VirtualHere USB client CLI";
    homepage = "https://www.virtualhere.com/usb_client_software";
    license = lib.licenses.unfree;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
