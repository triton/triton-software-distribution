{ stdenv
, asciidoc
, docbook_xml_dtd_45
, docbook-xsl
, fetchurl
, gettext
, libxslt
, makeWrapper
, xmlto

, coreutils
, cpio
, curl
, expat
, gawk
, gnugrep
, gnused
, openssl
, pcre
, perl
, python
, zlib
}:

let
  path = [
    coreutils
    gawk
    gettext
    gnugrep
    gnused
  ];

  version = "2.11.1";

  tarballUrls = [
    "mirror://kernel/software/scm/git/git-${version}.tar"
  ];
in
stdenv.mkDerivation rec {
  name = "git-${version}";

  src = fetchurl {
    urls = map (n: "${n}.xz") tarballUrls;
    hashOutput = false;
    sha256 = "c0a779cae325d48a1d5ba08b6ee1febcc31d0657a6da01fd1dec1c6e10976415";
  };

  patches = [
    ./symlinks-in-bin.patch
  ];

  nativeBuildInputs = [
    asciidoc
    docbook_xml_dtd_45
    docbook-xsl
    gettext
    libxslt
    makeWrapper
    xmlto
  ];

  buildInputs = [
    curl
    expat
    openssl
    pcre
    zlib
  ];

  # required to support pthread_cancel()
  NIX_LDFLAGS = "-lgcc_s";

  makeFlags = [
    "SHELL_PATH=${stdenv.shell}"
    "SANE_TOOL_PATH=${stdenv.lib.concatStringsSep ":" path}"
    "USE_LIBPCRE=1"
    "GNU_ROFF=1"
    "PERL_PATH=${perl}/bin/perl"
    "PYTHON_PATH=${python}/bin/python"
    "NO_TCLTK=1"
    "HAVE_CLOCK_GETTIME=1"
    "HAVE_CLOCK_MONOTONIC=1"
    "NO_INSTALL_HARDLINKS=1"
    "prefix=\${out}"
    "sysconfdir=/etc"
  ];

  buildFlags = [
    "all"
    "man"
  ];

  installTargets = [
    "install"
    "install-man"
  ];

  passthru = {
    srcVerification = fetchurl rec {
      failEarly = true;
      pgpDecompress = true;
      pgpsigUrls = map (n: "${n}.sign") tarballUrls;
      pgpKeyFingerprint = "96E0 7AF2 5771 9559 80DA  D100 20D0 4E5A 7136 60A7";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    description = "Distributed version control system";
    homepage = http://git-scm.com/;
    license = licenses.gpl2;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
