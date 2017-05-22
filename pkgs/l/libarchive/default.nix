{ stdenv
, autoreconfHook
, fetchFromGitHub

, acl
, attr
, bzip2
, e2fsprogs
, libxml2
, lz4
, lzo
, pcre
, openssl
, xz
, zlib
}:

stdenv.mkDerivation rec {
  name = "libarchive-2017-05-21";

  src = fetchFromGitHub {
    version = 3;
    owner = "libarchive";
    repo = "libarchive";
    rev = "328453a041e2ead52bf2c64b778a29f99bd17f14";
    sha256 = "8f263d675c238fa667de69bc39a673ccf8f01297d061e7facc685273d2d9d06e";
  };

  nativeBuildInputs = [
    autoreconfHook
  ];

  buildInputs = [
    acl
    attr
    bzip2
    e2fsprogs
    libxml2
    lz4
    lzo
    pcre
    openssl
    xz
    zlib
  ];

  postPatch = ''
    sed -i 's,-Werror ,,g' Makefile.am
  '';

  configureFlags = [
    "--with-zlib"
    "--with-bz2lib"
    "--with-iconv"
    "--with-lz4"
    "--with-lzma"
    "--with-lzo2"
    "--without-nettle"
    "--with-openssl"
    "--with-xml2"
    "--without-expat"
    "--enable-posix-regex-lib"
    "--enable-xattr"
    "--enable-acl"
  ];

  meta = with stdenv.lib; {
    description = "Multi-format archive and compression library";
    homepage = http://libarchive.org;
    license = licenses.bsd3;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
