{ stdenv
, fetchurl
, pythonPackages
, yasm # internal libav

, bzip2
, glib
, gst-plugins-base
, gstreamer
, orc
, xz
, zlib # internal libav
}:

let
  inherit (stdenv.lib)
    enFlag;
in

stdenv.mkDerivation rec {
  name = "gst-libav-1.8.2";

  src = fetchurl rec {
    url = "https://gstreamer.freedesktop.org/src/gst-libav/${name}.tar.xz";
    sha256Url = "${url}.sha256sum";
    sha256 = "b5f3c7a27b39b5f5c2f0bfd546b0c655020faf6b38d27b64b346c43e5ebf687a";
  };

  nativeBuildInputs = [
    pythonPackages.python
    yasm
  ];

  buildInputs = [
    bzip2
    glib
    gst-plugins-base
    gstreamer
    orc
    xz
    zlib
  ];

  configureFlags = [
    "--disable-maintainer-mode"
    (enFlag "orc" (orc != null) null)
    "--disable-fatal-warnings"
    "--disable-extra-checks"
    "--disable-valgrind"
    "--disable-gcov"
    "--disable-gtk-doc"
    "--disable-gtk-doc-html"
    "--disable-gtk-doc-pdf"
    "--enable-gobject-cast-checks"
    "--enable-glib-asserts"
    "--enable-Bsymbolic"
    "--disable-static-plugins"
    "--enable-gpl"
    # Upstream dropped support for system libav
    # http://bugzilla.gnome.org/show_bug.cgi?id=758183
    "--without-system-libav"
  ];

  meta = with stdenv.lib; {
    description = "FFmpeg based gstreamer plugin";
    homepage = http://gstreamer.freedesktop.org;
    license = licenses.gpl2;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
