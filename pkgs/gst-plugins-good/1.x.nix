{ stdenv
, fetchurl
, python

, aalib
, bzip2
, cairo
, flac
, gdk-pixbuf
, glib
, gst-plugins-base
, gstreamer
, libcaca
, libgudev
, jack2_lib
, libjpeg
, libpng
, pulseaudio_lib
, libshout
, libsoup
, v4l_lib
, libvpx
, orc
, speex
, taglib
, wavpack
, xorg
, zlib
}:

with {
  inherit (stdenv.lib)
    enFlag
    wtFlag;
};

stdenv.mkDerivation rec {
  name = "gst-plugins-good-1.8.0";

  src = fetchurl rec {
    url = "https://gstreamer.freedesktop.org/src/gst-plugins-good/${name}.tar.xz";
    sha256Url = "${url}.sha256sum";
    sha256 = "c20c134d47dbc238d921707a3b66da709c2b4dd89f9d267cec13d1ddf16e9f4d";
  };

  nativeBuildInputs = [
    python
  ];

  buildInputs = [
    aalib
    bzip2
    cairo
    flac
    gdk-pixbuf
    glib
    gst-plugins-base
    gstreamer
    libcaca
    libgudev
    jack2_lib
    libjpeg
    libpng
    pulseaudio_lib
    libshout
    libsoup
    v4l_lib
    libvpx
    orc
    speex
    taglib
    wavpack
    zlib
    xorg.libX11
    xorg.libXext
  ];

  configureFlags = [
    "--disable-maintainer-mode"
    "--enable-nls"
    "--enable-rpath"
    "--disable-fatal-warnings"
    "--disable-extra-checks"
    "--disable-debug"
    "--disable-profiling"
    "--disable-valgrind"
    "--disable-gcov"
    "--disable-examples"
    "--enable-external"
    "--enable-experimental"
    "--disable-gtk-doc"
    "--disable-gtk-doc-html"
    "--disable-gtk-doc-pdf"
    "--enable-gobject-cast-checks"
    "--enable-glib-asserts"
    (enFlag "orc" (orc != null) null)
    "--enable-Bsymbolic"
    "--disable-static-plugins"
    # Internal plugins
    "--enable-alpha"
    "--enable-apetag"
    "--enable-audiofx"
    "--enable-audioparsers"
    "--enable-auparse"
    "--enable-autodetect"
    "--enable-avi"
    "--enable-cutter"
    "--disable-debugutils"
    "--enable-deinterlace"
    "--enable-dtmf"
    "--enable-effectv"
    "--enable-equalizer"
    "--enable-flv"
    "--enable-flx"
    "--enable-goom"
    "--enable-goom2k1"
    "--enable-icydemux"
    "--enable-id3demux"
    "--enable-imagefreeze"
    "--enable-interleave"
    "--enable-isomp4"
    "--enable-law"
    "--enable-level"
    "--enable-matroska"
    "--enable-monoscope"
    "--enable-multifile"
    "--enable-multipart"
    "--enable-replaygain"
    "--enable-rtp"
    "--enable-rtpmanager"
    "--enable-rtsp"
    "--enable-shapewipe"
    "--enable-smpte"
    "--enable-spectrum"
    "--enable-udp"
    "--enable-videobox"
    "--enable-videocrop"
    "--enable-videofilter"
    "--enable-videomixer"
    "--enable-wavenc"
    "--enable-wavparse"
    "--enable-y4m"
    # External plugins
    "--disable-directsound"
    "--enable-waveform"
    "--disable-oss"
    "--disable-oss4"
    "--disable-sunaudio"
    "--disable-osx_audio"
    "--disable-osx_video"
    (enFlag "gst_v4l2" (v4l_lib != null) null)
    (enFlag "v4l2-probe" (v4l_lib != null) null)
    (enFlag "x" (xorg != null) null)
    (enFlag "aalib" (aalib != null) null)
    "--disable-aalibtest"
    (enFlag "cairo" (cairo != null) null)
    (enFlag "flac" (flac != null) null)
    (enFlag "gdk_pixbuf" (gdk-pixbuf != null) null)
    (enFlag "jack" (jack2_lib != null) null)
    (enFlag "jpeg" (libjpeg != null) null)
    (enFlag "libcaca" (libcaca != null) null)
    "--disable-libdv"
    (enFlag "libpng" (libpng != null) null)
    (enFlag "pulse" (pulseaudio_lib != null) null)
    "--disable-dv1394"
    (enFlag "shout2" (libshout != null) null)
    (enFlag "soup" (libsoup != null) null)
    (enFlag "speex" (speex != null) null)
    (enFlag "taglib" (taglib != null) null)
    (enFlag "vpx" (libvpx != null) null)
    (enFlag "wavpack" (wavpack != null) null)
    (enFlag "zlib" (zlib != null) null)
    (enFlag "bz2" (bzip2 != null) null)
    (wtFlag "--with-gudev" (libgudev != null) null)
    (wtFlag "--with-libv4l2" (v4l_lib != null) null)
  ];

  meta = with stdenv.lib; {
    description = "Basepack of plugins for GStreamer";
    homepage = http://gstreamer.freedesktop.org;
    license = licenses.lgpl2Plus;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
