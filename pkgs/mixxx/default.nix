{ stdenv
, fetchurl
, scons

, chromaprint
, faad2
, ffmpeg_2
, fftw_double
, flac
, libid3tag
, libmad
, libmodplug
, libshout
, libsndfile
, libusb
, libvorbis
, mesa_noglu
, mp4v2
, opus
, opusfile
, portaudio
, portmidi
, protobuf-cpp
, qt5
, rubberband
, soundtouch
, sqlite
, taglib
, vamp
, wavpack
, xorg
}:

let
  inherit (stdenv.lib)
    scFlag;
in

stdenv.mkDerivation rec {
  name = "mixxx-${version}";
  version = "2.0.0";

  src = fetchurl {
    url = "https://downloads.mixxx.org/${name}/${name}-src.tar.gz";
    sha256 = "0vb71w1yq0xwwsclrn2jj9bk8w4n14rfv5c0aw46c11mp8xz7f71";
  };

  nativeBuildInputs = [
    scons
  ];

  buildInputs = [
    chromaprint
    faad2
    ffmpeg_2
    fftw_double
    flac
    libid3tag
    libmad
    libmodplug
    libshout
    libsndfile
    libusb
    libvorbis
    mesa_noglu
    mp4v2
    opus
    opusfile
    portaudio
    portmidi
    protobuf-cpp
    qt5
    rubberband
    soundtouch
    sqlite
    taglib
    vamp.vampSDK
    wavpack
    xorg.libX11
  ];

  postPatch = ''
    sed -i build/depends.py \
      -e 's/"which /"type -P /'
  '';

  sconsFlags = [
    "build=release"
    "qt5=1"
    "qtdir=${qt5}"

    "opengles=0"
    "hss1394=0"
    (scFlag "hid" (libusb != null))
    (scFlag "bulk" (libusb != null))
    (scFlag "mad" (libmad != null))
    "coreaudio=0"
    "mediafoundation=0"
    "ipod=0"
    "vinylcontrol=1"
    (scFlag "vamp" (vamp.vampSDK != null))
    (scFlag "modplug" (libmodplug != null))
    (scFlag "faad" (faad2 != null))
    (scFlag "wv" (wavpack != null))
    "color=0"
    "asan=0"
    "perftools=0"
    "asmlib=0"
    "buildtime=0"
    "qtdebug=0"
    "verbose=0"
    "profiling=0"
    "test=0"
    (scFlag "shoutcast" (libshout != null))
    (scFlag "opus" (opus != null))
    (scFlag "ffmpeg" (ffmpeg_2 != null))
    "optimize=portable"
    "autodjcrates=1"
    "macappstore=0"
    "localecompare=1"
  ];

  buildPhase = ''
    runHook 'preBuild'
    mkdir -p "$out"
    scons \
      -j$NIX_BUILD_CORES -l$NIX_BUILD_CORES \
      $sconsFlags "prefix=$out"
    runHook 'postBuild'
  '';

  installPhase = ''
    runHook 'preInstall'
    scons $sconsFlags "prefix=$out" install
    runHook 'postInstall'
  '';

  meta = with stdenv.lib; {
    description = "Digital DJ mixing software";
    homepage = "http://mixxx.org/";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
