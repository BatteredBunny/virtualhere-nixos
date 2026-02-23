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
      url = "https://web.archive.org/web/20260222003530id_/https://www.virtualhere.com/sites/default/files/usbclient/vhclientx86_64";
      hash = "sha256-iZ0Ei7b6h4OJlehJlp0ap+YaoVqkrNeIDsHyIrXfUhI=";
    };
    vhclientarm64 = {
      url = "https://web.archive.org/web/20260223002934id_/https://www.virtualhere.com/sites/default/files/usbclient/vhclientarm64";
      hash = "sha256-pNTLHUwiL6I6IqtpJW0tULvOTPPdUqFRhKerUfuStH0=";
    };
  };
in
stdenv.mkDerivation rec {
  pname = "virtualhere-client-cli";
  version = "unstable-2026-02-23";

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
