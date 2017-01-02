{ stdenv
, fetchurl
, perl

, openssl
}:

stdenv.mkDerivation rec {
  name = "ldns-1.7.0";

  src = fetchurl {
    url = "http://www.nlnetlabs.nl/downloads/ldns/${name}.tar.gz";
    hashOutput = false;
    sha256 = "c19f5b1b4fb374cfe34f4845ea11b1e0551ddc67803bd6ddd5d2a20f0997a6cc";
  };

  nativeBuildInputs = [
    perl
  ];

  buildInputs = [
    openssl
  ];

  postPatch = ''
    patchShebangs doc/doxyparse.pl
  '';

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    "--disable-gost"
    "--enable-ed25519"
    "--enable-ed448"
    "--with-drill"
    "--with-ssl=${openssl}"
    "--with-ca-file=/etc/ssl/certs/ca-certificates.crt"
  ];

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.asc") src.urls;
      sha1Urls = map (n: "${n}.sha1") src.urls;
      sha256Urls = map (n: "${n}.sha256") src.urls;
      pgpKeyFingerprint = "DC34 EE5D B241 7BCC 151E  5100 E5F8 F821 2F77 A498";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    description = "Library with the aim of simplifying DNS programming in C";
    license = licenses.bsd3;
    homepage = "http://www.nlnetlabs.nl/projects/ldns/";
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
