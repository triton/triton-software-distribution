{ stdenv
, fetchurl
, python

, c-ares
, http-parser
, icu
, libuv
, openssl_1-0-2
, zlib
}:

let
  version = "9.1.0";

  dirUrls = [
    "https://nodejs.org/dist/v${version}"
  ];
in
stdenv.mkDerivation rec {
  name = "nodejs-${version}";

  src = fetchurl {
    urls = map (n: "${n}/node-v${version}.tar.xz") dirUrls;
    hashOutput = false;
    sha256 = "7e34d581332aedc85306859e613a81cce2531bdd30eef358cb54db8a4f5c3c49";
  };

  nativeBuildInputs = [
    python
  ];

  buildInputs = [
    c-ares
    http-parser
    icu
    libuv
    openssl_1-0-2
    zlib
  ];

  postPatch = ''
    patchShebangs configure
  '';

  configureFlags = [
    "--shared-http-parser"
    "--shared-libuv"
    "--shared-openssl"
    "--shared-zlib"
    "--shared-cares"
    "--with-intl=system-icu"
  ];

  dontDisableStatic = true;

  setupHook = ./setup-hook.sh;

  # Fix scripts like npm that depend on node
  postInstall = ''
    export PATH="$out/bin:$PATH"
    command -v node
    while read file; do
      patchShebangs "$file"
    done < <(grep -r '#!/usr/bin/env' $out | awk -F: '{print $1}')
  '';

  passthru = {
    srcVerification = fetchurl rec {
      failEarly = true;
      sha256Urls = map (n: "${n}/SHASUMS256.txt.asc") dirUrls;
      #pgpsigSha256Urls = map (n: "${n}.asc") sha256Urls;
      pgpKeyFingerprints = [
        # Rod Vagg
        "DD8F 2338 BAE7 501E 3DD5  AC78 C273 792F 7D83 545D"
        # Evan Lucas
        "B9AE 9905 FFD7 803F 2571  4661 B63B 535A 4C20 6CA9"
        # Jeremiah Senkpiel
        "FD3A 5288 F042 B685 0C66  B31F 09FE 4473 4EB7 990E"
        # Colin Ihrig
        "94AE 3667 5C46 4D64 BAFA  68DD 7434 390B DBE9 B9C5"
        # Myles Borins
        "C4F0 DFFF 4E8C 1A82 3640  9D08 E73B C641 CC11 F4C8"
        # James M Snell
        "71DC FD28 4A79 C3B3 8668  286B C97E C7A0 7EDE 3FC1"
        # Italo A. Casas
        "5673 0D54 0102 8683 275B  D23C 23EF EFE9 3C4C FFFE"
      ];
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
