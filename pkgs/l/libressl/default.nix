{ stdenv
, fetchurl
}:

let
  baseUrl = "mirror://openbsd/LibreSSL";
in

stdenv.mkDerivation rec {
  name = "libressl-2.5.1";

  src = fetchurl {
    url = "${baseUrl}/${name}.tar.gz";
    hashOutput = false;  # Upstream provides it directly
    sha256 = "f71ae0a824b78fb1a47ffa23c9c26e9d96c5c9b29234eacedce6b4c7740287cd";
  };

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
  ];

  preInstall = ''
    installFlagsArray+=(
      "sysconfdir=$out/etc"
      "localstatedir=$TMPDIR"
    )
  '';

  passthru = {
    srcVerification = fetchurl rec {
      failEarly = true;
      pgpsigUrl = map (n: "${n}.asc") src.urls;
      #sha256Url = "${baseUrl}/SHA256";
      #pgpsigSha256Url = "${sha256Url}.asc";
      pgpKeyFile = ./signing.key;
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    license = licenses.bsd3;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
