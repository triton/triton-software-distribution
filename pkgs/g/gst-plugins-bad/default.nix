{ stdenv
, fetchurl
, lib
, meson
, ninja
, python3

, bzip2
, chromaprint
, curl
, faac
, faad2
, flite
, game-music-emu
, glib
, gobject-introspection
, gsm
, gst-plugins-base
, gstreamer
, gtk_3
, ladspa-sdk
, libass
, libbs2b
, libmms
, libmodplug
, librsvg
, libsndfile
, libvdpau
, libvisual
, libwebp
, libx11
, musepack
, openal
, opencv
, openexr
, opengl-dummy
, openh264
, openjpeg
, openssl
, opus
, orc
, qt5
, rtmpdump
, schroedinger
, soundtouch
, spandsp
#, vo-aacenc
#, vo-armwbenc
, wayland
, x265

, channel
}:

let
  inherit (lib)
    concatStringsSep
    optionals;

  gl_platforms = [ ]
    ++ optionals opengl-dummy.glx [
      "glx"
    ] ++ optionals opengl-dummy.egl [
      "egl"
    ];

  sources = {
    "1.14" = {
      version = "1.14.2";
      sha256 = "34fab7da70994465a64468330b2168a4a0ed90a7de7e4c499b6d127c6c1b1eaf";
    };
  };
  source = sources."${channel}";
in
stdenv.mkDerivation rec {
  name = "gst-plugins-bad-${source.version}";

  src = fetchurl rec {
    urls = map (n: "${n}/${name}.tar.xz") [
      "https://gstreamer.freedesktop.org/src/gst-plugins-bad"
      "mirror://gnome/sources/gst-plugins-bad/${channel}"
    ];
    hashOutput = false;
    inherit (source) sha256;
  };

  nativeBuildInputs = [
    meson
    ninja
    python3
  ];

  buildInputs = [
    bzip2
    chromaprint
    curl
    faac
    faad2
    flite
    game-music-emu
    glib
    gobject-introspection
    gsm
    gst-plugins-base
    gstreamer
    gtk_3
    ladspa-sdk
    libass
    libbs2b
    libmms
    libmodplug
    opus
    librsvg
    libvdpau
    libvisual
    libwebp
    libx11
    musepack
    openal
    opencv
    openexr
    opengl-dummy
    openh264
    openjpeg
    openssl
    orc
    qt5
    rtmpdump
    schroedinger
    soundtouch
    spandsp
    #vo-aacenc
    #vo-armwbenc
    wayland
    x265
  ];

  postPatch = ''
    patchShebangs gst-libs/gst/interfaces/build_mkenum.py
    patchShebangs gst-libs/gst/mpegts/mpegts_enum.py
    patchShebangs gst-libs/gst/webrtc/webrtc_mkenum.py
  '';

  mesonFlags = [
    "-Duse_orc=yes"
    #"-Dwith_gl_api=${if opengl-dummy.glesv2 then "gles2" else "opengl"}"
    "-Dwith_gl_api=opengl"
    "-Dwith_gl_platform=${concatStringsSep "," gl_platforms}"
    "-Ddisable_introspection=false"
  ];

  passthru = {
    srcVerification = fetchurl {
      inherit (src)
        outputHash
        outputHashAlgo
        urls;
      sha256Urls = map (n: "${n}.sha256sum") src.urls;
      pgpsigUrls = map (n: "${n}.asc") src.urls;
      pgpKeyFingerprints = [
        # Sebastian Dr??ge
        "7F4B C7CC 3CA0 6F97 336B  BFEB 0668 CC14 86C2 D7B5"
        # Tim-Philipp M??ller
        "D637 032E 45B8 C658 5B94  5656 5D2E EE6F 6F34 9D7C"
      ];
      failEarly = true;
    };
  };

  meta = with lib; {
    description = "Less plugins for GStreamer";
    homepage = http://gstreamer.freedesktop.org;
    license = licenses.lgpl2;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
