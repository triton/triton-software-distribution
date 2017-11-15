{ stdenv
, bison
, fetchTritonPatch
, fetchurl

, db
, libasr
, libbsd
, libevent
, libressl
, pam
, zlib
}:

let
  version = "6.0.2p1";

  name = "opensmtpd-${version}";

  baseUrls = [
    "https://www.opensmtpd.org/archives/${name}"
  ];
in
stdenv.mkDerivation rec {
  inherit name;

  src = fetchurl {
    url = map (n: "${n}.tar.gz") baseUrls;
    multihash = "QmTaJoYN8ayemCRNJyobCD94dnAk7hS9AsamymXLFgRNp2";
    hashOutput = false;
    sha256 = "2af9b6d08784c7e546bf124bb61e311a6aa0c9835507710a76f5c242383190ac";
  };

  nativeBuildInputs = [
    bison
  ];

  buildInputs = [
    db
    libasr
    libbsd
    libevent
    libressl
    pam
    zlib
  ];

  patches = [
    (fetchTritonPatch {
      rev = "04a8e575c23f73ccefa548f7b9650db2491f39dc";
      file = "opensmtpd/libexec-env.patch";
      sha256 = "2ba90f17d419a0cef94c01a2ca2772828a280c791e7ca7a112c1446ad95833a0";
    })
  ];

  postPatch = /* Can't setuid inside nix-builder */ ''
    sed -i mk/smtpctl/Makefile.in \
      -e 's/chmod 2555/chmod 0555/'
  '';

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    "--with-mantype=doc"
    "--without-auth-bsdauth"
    "--with-auth-pam=smtpd"
    "--with-user-smtpd=smtpd"
    "--with-user-queue=smtpq"
    "--with-path-socket=/run"
    "--with-path-CAfile=/etc/ssl/certs/ca-certificates.crt"
    "--with-table-db"
  ];

  preInstall = ''
    installFlagsArray+=(
      "sysconfdir=$out/etc"
    )
  '';

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      signifyUrls = map (n: "${n}.sum.sig") baseUrls;
      signifyPub = "RWSoKNlSRN/G8zpyHzdK1MVuLrQi3J1Yfo9XsjgFHnCvabkcb6bBRBf0";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    homepage = https://www.opensmtpd.org/;
    license = licenses.isc;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
