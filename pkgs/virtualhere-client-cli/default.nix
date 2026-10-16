{
  stdenv,
  fetchurl,
  lib,
  versionCheckHook,
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
      url = "https://web.archive.org/web/20261001041247id_/https://www.virtualhere.com/sites/default/files/usbclient/vhclientx86_64";
      hash = "sha256-1m1BoS4RN8463sH4UZh6K/s8xiypaigGRqvNbZxOxVQ=";
    };
    vhclientarm64 = {
      url = "https://web.archive.org/web/20261001041257id_/https://www.virtualhere.com/sites/default/files/usbclient/vhclientarm64";
      hash = "sha256-RcmJCqcbaw5sKy75lhlqr9XBgEQGpl/DIKK/pxEI0mM=";
    };
  };
in
stdenv.mkDerivation rec {
  pname = "virtualhere-client-cli";
  version = "6.0.3";

  src = fetchurl sources.${binaryName};

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/${binaryName}
    chmod 0755 $out/bin/${binaryName}
    ln -s $out/bin/${binaryName} $out/bin/virtualhere-client-cli
  '';

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--help";

  passthru.updateScript = ./update.sh;

  meta = {
    mainProgram = "virtualhere-client-cli";
    description = "VirtualHere USB client CLI";
    homepage = "https://www.virtualhere.com/usb_client_software";
    license = lib.licenses.unfree;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
