{ fetchurl, stdenv, pkgconfig, glib, gstreamer, gst_plugins_base
, libdvdnav, libdvdread, orc }:

stdenv.mkDerivation rec {
  name = "gst-plugins-bad-0.10.23";

  src = fetchurl {
    urls = [
      "${meta.homepage}/src/gst-plugins-bad/${name}.tar.bz2"
      "mirror://gentoo/${name}.tar.bz2"
      ];
    sha256 = "148lw51dm6pgw8vc6v0fpvm7p233wr11nspdzmvq7bjp2cd7vbhf";
  };

  patches = [
    # Patches from 0.10 branch fixing h264 baseline decoding
    ./gst-plugins-bad-0.10.23-CVE-2015-0797.patch
  ];

  buildInputs =
    [ pkgconfig glib gstreamer gst_plugins_base libdvdnav libdvdread orc ];

  enableParallelBuilding = true;

  meta = {
    homepage = http://gstreamer.freedesktop.org;

    description = "‘Bad’ (potentially low quality) plug-ins for GStreamer";

    maintainers = [stdenv.lib.maintainers.raskin];
    platforms = stdenv.lib.platforms.linux;

    license = stdenv.lib.licenses.lgpl2Plus;
  };
}
