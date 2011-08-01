{ stdenv
, fetchurl
, unzip
, zip
, procps
, coreutils
, gnugrep
, gnused
, alsaLib
, ant
, freetype
, cups
, gawk
, which
, jdk
, findutils
, glibc
, binutils
}:

stdenv.mkDerivation rec {
  name = "openjdk-7b127";

  src = fetchurl {
    url = http://www.java.net/download/openjdk/jdk7/promoted/b147/openjdk-7-fcs-src-b147-27_jun_2011.zip;
    sha256 = "1qhwlz9y5qmwmja4qnxg6sn3pgsg1i11fb9j41w8l26acyhk34rs";
  };

  buildInputs = [ unzip procps ant which zip ];

  postUnpack = ''
    sed -i s@/usr/bin/test@${coreutils}/bin/test@ \
      openjdk/hotspot/make/linux/makefiles/sa.make 

    sed -i s@/bin/ls@${coreutils}/bin/ls@ \
      openjdk/hotspot/make/linux/makefiles/sa.make 
  '';

  makeFlags = ''
    MKDIR=${coreutils}/bin/mkdir \
    LDD=${glibc}/bin/ldd \
    NM=${binutils}/bin/nm \
    READELF=${binutils}/bin/readelf \
    MV=${coreutils}/bin/mv \
    TOUCH=${coreutils}/bin/touch \
    CP=${coreutils}/bin/cp \
    CHMOD=${coreutils}/bin/chmod \
    ECHO=${coreutils}/bin/echo \
    CAT=${coreutils}/bin/cat \
    GREP=${gnugrep}/bin/grep \
    EGREP=${gnugrep}/bin/egrep \
    DATE=${coreutils}/bin/date \
    PWD=${coreutils}/bin/pwd \
    TR=${coreutils}/bin/tr \
    SED=${gnused}/bin/sed \
    ALSA_INCLUDE=${alsaLib}/include/alsa/version.h \
    HEAD=${coreutils}/bin/head \
    ZIPEXE=${zip}/bin/zip \
    FREETYPE_HEADERS_PATH=${freetype}/include \
    FREETYPE_LIB_PATH=${freetype}/lib \
    MILESTONE="release" \
    BUILD_NUMBER="127" \
    CUPS_HEADERS_PATH="${cups}/include" \
    USRBIN_PATH="/" \
    COMPILER_PATH="/" \
    DEVTOOLS_PATH="/" \
    NAWK=${gawk}/bin/gawk \
    PRINTF=${coreutils}/bin/printf \
    BOOTDIR=${jdk} \
    FIND=${findutils}/bin/find \
    ALLOW_DOWNLOADS=true \
    CC=${stdenv.gcc}/bin/gcc
  '';

  configurePhase = ''
    make ${makeFlags} sanity
  '';
}

