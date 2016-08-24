{ stdenv
, fetchurl
, cmake
, docbook_xml_dtd_45
, docbook-xsl
, libxslt
, ninja
, perl

#, automoc4
, chromaprint
, dbus
, ffmpeg
, flac
, gstreamer
, id3lib
, libogg
, libvorbis
, mp4v2
#, phonon
, python
, qt5
, readline
, taglib
, zlib
}:

let
  inherit (stdenv.lib)
    cmFlag;
in
stdenv.mkDerivation rec {
  name = "kid3-${version}";
  version = "3.4.2";

  src = fetchurl {
    url = "mirror://sourceforge/kid3/kid3/${version}/${name}.tar.gz";
    multihash = "QmShzrc31XbMaWYzBnAn8SABTJ45oLQJfnzzpE8nS1jroE";
    allowHashOutput = false;
    sha256 = "5c0707f1be73c486d09522ca086693d3ee830b7a28a88dbd2c010c5494256a3e";
  };

  nativeBuildInputs = [
    cmake
    docbook_xml_dtd_45
    docbook-xsl
    libxslt
    ninja
    perl
  ];

  buildInputs = [
    chromaprint
    ffmpeg
    flac
    id3lib
    mp4v2
    libogg
    libvorbis
    #phonon
    python
    qt5
    readline
    taglib
    zlib
  ];

  preConfigure = ''
    export DOCBOOKDIR="${docbook-xsl}/xml/xsl/docbook/"
  '';

  cmakeFlags = [
    #QT_QMAKE_EXECUTABLE:FILEPATH=NOTFOUND
    #Qt5Core_DIR:PATH=Qt5Core_DIR-NOTFOUND
    "-DWITH_APPS=QT;CLI" #KDE
    (cmFlag "WITH_CHROMAPRINT" (chromaprint != null))
    #WITH_CHROMAPRINT_FFMPEG:BOOL=OFF
    (cmFlag "WITH_DBUS" (dbus != null))
    (cmFlag "WITH_FFMPEG" (ffmpeg != null))
    (cmFlag "WITH_FLAC" (flac != null))
    (cmFlag "WITH_GSTREAMER" (gstreamer != null))
    (cmFlag "WITH_ID3LIB" (id3lib != null))
    (cmFlag "WITH_MP4V2" (mp4v2 != null))
    (cmFlag "WITH_PHONON" false)
    #WITH_QAUDIODECODER:BOOL=OFF
    #WITH_QML:BOOL=ON
    "-DWITH_QT4=OFF"
    "-DWITH_QT5=ON"
    (cmFlag "WITH_READLINE" (readline != null))
    (cmFlag "WITH_TAGLIB" (taglib != null))
    #WITH_UBUNTUCOMPONENTS:BOOL=OFF
    (cmFlag "WITH_VORBIS" (libvorbis != null))
  ];

  passthru = {
    srcVerification = fetchurl rec {
      inherit (src)
        outputHash
        outputHashAlgo
        urls;
      failEarly = true;
      pgpsigUrls = map (n: "${n}.asc") src.urls;
      pgpKeyFingerprint = "7D09 794C 2812 F621 94B0  81C1 4CAD 3442 6E35 4DD2";
    };
  };

  meta = with stdenv.lib; {
    description = "A simple and powerful audio tag editor";
    homepage = http://kid3.sourceforge.net/;
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
