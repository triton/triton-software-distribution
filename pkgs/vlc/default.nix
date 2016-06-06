{ stdenv
, fetchTritonPatch
, fetchurl
, gettext

, a52dec
, alsa-lib
, avahi
, bzip2
, dbus
, faad2
, flac
, ffmpeg_2
, freefont_ttf
, fribidi
, gnutls
, gvfs
, jack2_lib
, libass
, libavc1394
, libbluray
, libcaca
, libcddb
, libdc1394
, libdvbpsi
, libdvdnav
, libebml
, libgcrypt
, libidn
, libkate
, libmad
, libmatroska
, libmtp
, liboggz
, libraw1394
, librsvg
, libsamplerate
, libtheora
, libtiff
, libtiger
, libupnp
, libva
, libvdpau
, libvorbis
, libxml2
, lua
, libmpeg2
, mesa_noglu
, opus
, perl
, pulseaudio_lib
, qt4
#, qt5
, samba_client
, schroedinger
, SDL
, SDL_image
, speex
, systemd_lib
, taglib
, unzip
, v4l_lib
, xorg
, xz
, zlib

, onlyLibVLC ? false
}:

let
  inherit (stdenv.lib)
    optional;
in

stdenv.mkDerivation rec {
  name = "vlc-${version}";
  version = "2.2.3";

  src = fetchurl {
    url = "http://get.videolan.org/vlc/${version}/${name}.tar.xz";
    allowHashOutput = false;
    sha256 = "b9d7587d35f13c3c981964c8cc8b03f1c7c8edf528be476b3ca1d2efedd5bf5b";
  };

  nativeBuildInputs = [
    gettext
  ];

  buildInputs = [
    a52dec
    alsa-lib
    avahi
    bzip2
    dbus
    faad2
    flac
    ffmpeg_2
    freefont_ttf
    fribidi
    gnutls
    gvfs
    jack2_lib
    libass
    libavc1394
    libbluray
    libcaca
    libcddb
    libdc1394
    libdvbpsi
    libdvdnav
    libdvdnav.libdvdread
    libebml
    libgcrypt
    libidn
    libkate
    libmad
    libmatroska
    libmtp
    liboggz
    libraw1394
    librsvg
    libsamplerate
    libtheora
    libtiff
    libtiger
    libupnp
    libva
    libvdpau
    libvorbis
    libxml2
    lua
    libmpeg2
    mesa_noglu
    opus
    perl
    pulseaudio_lib
    qt4
    #qt5.qtbase
    samba_client
    schroedinger
    SDL
    SDL_image
    speex
    systemd_lib
    taglib
    unzip
    v4l_lib
    xorg.xcbutilkeysyms
    xorg.libX11
    xorg.libxcb
    xorg.libXpm
    xorg.libXv
    xorg.libXvMC
    xorg.xproto
    xz
    zlib
  ];

  patches = [
    (fetchTritonPatch {
      rev = "2e96cc8e06eaf6ad9643acd1fdddb23aba7759ea";
      file = "vlc/lua_53_compat.patch";
      sha256 = "d1cb88a1037120ea83ef75b2a13039a16825516b776d71597d0e2eae5df2d8fa";
    })
  ];

  postPatch = ''
    sed -e "s@/bin/echo@echo@g" -i configure
  '';

  configureFlags = [
    "--enable-alsa"
    "--with-kde-solid=$out/share/apps/solid/actions"
    "--enable-dc1394"
    "--enable-ncurses"
    "--enable-vdpau"
    "--enable-dvdnav"
    "--enable-samplerate"
  ] ++ optional onlyLibVLC  "--disable-vlc";

  preBuild = ''
    substituteInPlace \
      modules/text_renderer/freetype.c \
      --replace /usr/share/fonts/truetype/freefont/FreeSerifBold.ttf \
      ${freefont_ttf}/share/fonts/truetype/FreeSerifBold.ttf
  '';

  bindnow = false;

  passthru = {
    srcVerified = fetchurl rec {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.asc") src.urls;
      sha256Urls = map (n: "${n}.sha256") src.urls;
      pgpKeyFingerprint = "65F7 C6B4 206B D057 A7EB  7378 7180 713B E58D 1ADC";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    description = "Cross-platform media player and streaming server";
    homepage = http://www.videolan.org/vlc/;
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [ ];
    platforms = with platforms;
      x86_64-linux;
  };
}
