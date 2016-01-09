{ stdenv, fetchurl
, docutils
, makeWrapper
, perl
, pkgconfig
, python
, which

, alsaLib
, ffmpeg
, freefont_ttf
, freetype
, libass
, libbluray
, libbs2b
, libcaca
, libdvdnav
, libdvdread
, libjack2
, libpng
, libpulseaudio
, libtheora
, libvdpau
, lua
, lua5_sockets
, mesa
, SDL2
, speex
, xorg
, youtube-dl

, vaapiSupport ? false, libva ? null
}:

with {
  inherit (stdenv.lib)
    optional
    optionals
    optionalString;
};

let
  # Purity: Waf is normally downloaded by bootstrap.py, but
  # for purity reasons this behavior should be avoided.
  waf = fetchurl {
    url = http://ftp.waf.io/pub/release/waf-1.8.12;
    sha256 = "12y9c352zwliw0zk9jm2lhynsjcf5jy0k1qch1c1av8hnbm2pgq1";
  };
in

stdenv.mkDerivation rec {
  name = "mpv-${version}";
  version = "0.14.0";

  src = fetchurl {
    url = "https://github.com/mpv-player/mpv/archive/v${version}.tar.gz";
    sha256 = "0cqjwl0xyg0sv1jflipfkvqjg32y0kqfh4gc3lyhqgv0hgs3fa84";
  };

  patchPhase = ''
    patchShebangs ./TOOLS/
  '';

  configureFlags = [
    "--enable-libmpv-shared"
    "--disable-libmpv-static"
    "--disable-static-build"
    "--enable-manpage-build"
    "--disable-build-date" # Purity
    "--enable-zsh-comp"
  ] ++ optional vaapiSupport "--enable-vaapi";

  NIX_LDFLAGS = "-lX11 -lXext";

  configurePhase = ''
    python ${waf} configure --prefix=$out $configureFlags
  '';

  nativeBuildInputs = [
    docutils
    makeWrapper
    perl
    python
    which
  ];

  buildInputs = [
    alsaLib
    ffmpeg
    freefont_ttf
    freetype
    libass
    libbluray
    libbs2b
    libcaca
    libdvdnav
    libdvdnav.libdvdread
    libdvdread
    libjack2
    libpng
    libpulseaudio
    libtheora
    libvdpau
    lua
    lua5_sockets
    mesa
    SDL2
    speex
    xorg.libpthreadstubs
    xorg.libX11
    xorg.libXext
    xorg.libXinerama
    xorg.libXScrnSaver
    xorg.libXv
    xorg.libXxf86vm
    youtube-dl
  ] ++ optional vaapiSupport libva;

  buildPhase = ''
    python ${waf} build
  '';

  installPhase = ''
    python ${waf} install

    # Use a standard font
    mkdir -p $out/share/mpv
    ln -s ${freefont_ttf}/share/fonts/truetype/FreeSans.ttf $out/share/mpv/subfont.ttf

    # Ensure youtube-dl is available in $PATH for MPV
    wrapProgram $out/bin/mpv --prefix PATH : "${youtube-dl}/bin"
  '';

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "A media player that supports many video formats";
    homepage = http://mpv.io;
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
  };
}
