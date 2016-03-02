{ stdenv
, fetchurl

, c-ares
, libssh2
, libxml2
, openssl
, sqlite
, zlib
}:

stdenv.mkDerivation rec {
  name = "aria2-${version}";
  version = "1.20.0";

  src = fetchurl {
    url = "https://github.com/tatsuhiro-t/aria2/releases/download/release-${version}/${name}.tar.xz";
    sha256 = "1l4gzz3yr0cl6a9xdy7843c5sb7afyq0i80wi2hasfpfdx5k95mz";
  };

  buildInputs = [
    openssl
    c-ares
    libxml2
    sqlite
    zlib
    libssh2
  ];

  configureFlags = [
    "--with-ca-bundle=/etc/ssl/certs/ca-certificates.crt"
  ];

  meta = with stdenv.lib; {
    homepage = https://github.com/tatsuhiro-t/aria2;
    description = "A lightweight, multi-protocol, multi-source, command-line download utility";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}
