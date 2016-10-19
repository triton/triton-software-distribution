{ stdenv
, fetchurl
, gettext
, ruby

, boost
, expat
, file
, flac
, libebml
, libmatroska
, libogg
, libvorbis
, pugixml
, qt5
, xdg-utils
, zlib
}:

let
  inherit (stdenv.lib)
    boolEn
    boolString
    boolWt
    optionals;
in
stdenv.mkDerivation rec {
  name = "mkvtoolnix-9.5.0";

  src = fetchurl {
    url = "https://mkvtoolnix.download/sources/${name}.tar.xz";
    multihash = "QmNek1av8NmWddXC296rut1Eo8Z921yvSdSDxMMWd7rXAi";
    sha256 = "dde9969c43ad04d03ded73934e52388d978d5947fc5d5528d1eb4dc722dc86c0";
  };

  nativeBuildInputs = [
    gettext
    ruby
  ];

  buildInputs = [
    boost
    expat
    file
    flac
    libebml
    libmatroska
    libogg
    libvorbis
    pugixml
    qt5
    xdg-utils
    zlib
  ];

  postPatch = ''
    patchShebangs ./rake.d/
    patchShebangs ./Rakefile
  '';

  configureFlags = [
    "--disable-debug"
    "--disable-profiling"
    "--enable-optimization"
    "--disable-precompiled-headers"
    "--${boolEn (qt5 != null)}-qt"
    "--disable-static-qt"
    "--enable-magic"
    "--${boolWt (flac != null)}-flac"
    "--without-curl"
    "--${boolWt (boost != null)}-boost"
    "--${boolWt (boost != null)}-boost-libdir${
      boolString (boost != null) "=${boost.lib}/lib" ""}"
    "--with-gettext"
    "--without-tools"
  ];

  buildPhase = ''
    ./drake -j $NIX_BUILD_CORES
  '';

  installPhase = ''
    ./drake -j $NIX_BUILD_CORES install
  '';

  passthru = {
    srcVerification = fetchurl {
      inherit (src)
        outputHash
        outputHashAlgo
        urls;
      failEarly = true;
      pgpsigUrls = map (n: "${n}.sig") src.urls;
      pgpKeyFingerprint = "D919 9745 B054 5F2E 8197  062B 0F92 290A 445B 9007";
    };
  };

  meta = with stdenv.lib; {
    description = "Cross-platform tools for Matroska";
    homepage = http://www.bunkus.org/videotools/mkvtoolnix/;
    license = licenses.gpl2;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
