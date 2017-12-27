{ stdenv
, fetchurl
, perl

, cyrus-sasl
, libbson
, openssl
, snappy
, zlib
}:

let
  version = "1.9.0";
in
stdenv.mkDerivation rec {
  name = "mongo-c-driver-${version}";

  src = fetchurl {
    url = "https://github.com/mongodb/mongo-c-driver/releases/download"
      + "/${version}/${name}.tar.gz";
    sha256 = "f1f725bd13bb58ee31e0b25d7940b84ad132d27383fba439f61b828cbe36feb5";
  };

  nativeBuildInputs = [
    perl
  ];

  buildInputs = [
    cyrus-sasl
    libbson
    openssl
    snappy
    zlib
  ];

  configureFlags = [
    "--disable-examples"
    "--disable-tests"
    "--enable-sasl=yes"
    "--enable-ssl=openssl"
    "--enable-crypto-system-profile"
    "--with-libbson=system"
    "--with-snappy=system"
    "--with-zlib=system"
  ];

  # Builders don't respect the nested include dir
  postInstall = ''
    incdir="$(echo "$out"/include/*)"
    mv "$incdir"/* "$out/include"
    rmdir "$incdir"
    ln -sv . "$incdir"
  '';

  meta = with stdenv.lib; {
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
