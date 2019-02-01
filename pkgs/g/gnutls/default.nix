{ stdenv
, autogen
, fetchurl
, which

, cryptodev_headers
, gmp
, libidn2
, libtasn1
, libunistring
, nettle
, p11-kit
, trousers
, unbound
}:

let
  tarballUrls = major: minor: [
    "mirror://gnupg/gnutls/v${major}/gnutls-${major}.${minor}.tar.xz"
  ];

  major = "3.6";
  minor = "6";
  version = "${major}.${minor}";
in
stdenv.mkDerivation rec {
  name = "gnutls-${version}";

  src = fetchurl {
    urls = tarballUrls major minor;
    hashOutput = false;
    sha256 = "bb9acab8af2ac430edf45faaaa4ed2c51f86e57cb57689be6701aceef4732ca7";
  };

  configureFlags = [
    "--disable-maintainer-mode"
    "--disable-doc"
    "--enable-manpages"
    "--disable-ssl2-support"
    "--enable-cryptodev"
    "--disable-tests"
    "--disable-full-test-suite"
    "--with-default-trust-store-file=/etc/ssl/certs/ca-certificates.crt"
    "--with-trousers-lib=${trousers}/lib"
    "--disable-dependency-tracking"
  ];

  nativeBuildInputs = [
    autogen
    which
  ];

  buildInputs = [
    cryptodev_headers
    gmp
    libidn2
    libtasn1
    libunistring
    nettle
    p11-kit
    trousers
    unbound
  ];

  passthru = {
    # Gnupg depends on this so we have to decouple this fetch from the rest of the build.
    srcVerification = fetchurl rec {
      failEarly = true;
      urls = tarballUrls "3.6" "6";
      inherit (src)
        outputHashAlgo;
      fullOpts = {
        pgpsigUrls = map (n: "${n}.sig") urls;
        pgpKeyFingerprint = "1F42 4189 05D8 206A A754  CCDC 29EE 58B9 9686 5171";
      };
      outputHash = "bb9acab8af2ac430edf45faaaa4ed2c51f86e57cb57689be6701aceef4732ca7";
    };
  };

  meta = with stdenv.lib; {
    description = "The GNU Transport Layer Security Library";
    homepage = http://www.gnu.org/software/gnutls/;
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
