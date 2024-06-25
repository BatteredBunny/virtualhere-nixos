{
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  name = "vhclientx86_64";

  src = fetchurl {
    url = "https://www.virtualhere.com/sites/default/files/usbclient/${name}";
    hash = "sha256-iahVFDwVxpe2+ieWEiOtOht/iGczMJfS0cGVadSI56I=";
  };

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/${name}
    chmod 0755 $out/bin/${name}
    ln -s $out/bin/${name} $out/bin/virtualhere-client-cli
  '';
}
