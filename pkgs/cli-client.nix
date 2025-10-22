{ stdenv
, fetchurl
, ...
}:
stdenv.mkDerivation rec {
  name = "vhclientx86_64";

  src = fetchurl {
    url = "https://www.virtualhere.com/sites/default/files/usbclient/${name}";
    hash = "sha256-UX9UP8DzFZ0nvVjUM/I86wU2jcQsNi5xLSOyewZ1HCk=";
  };

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/${name}
    chmod 0755 $out/bin/${name}
    ln -s $out/bin/${name} $out/bin/virtualhere-client-cli
  '';
}
