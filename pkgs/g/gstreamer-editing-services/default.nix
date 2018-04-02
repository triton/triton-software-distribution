{ stdenv
, fetchurl
, flex
, lib
, meson
, ninja

, glib
, gobject-introspection
, gst-plugins-base
, gstreamer
, libxml2

, channel
}:

let
  inherit (lib)
    boolEn;

  sources = {
    "1.14" = {
      version = "1.14.0";
      sha256 = "8d5f90eb532f4cf4aa1466807ef92b05bd1705970d7aabe10066929bbc698d91";
    };
  };

  source = sources."${channel}";
in
stdenv.mkDerivation rec {
  name = "gstreamer-editing-services-${source.version}";

  src = fetchurl rec {
    urls = map (n: "${n}/${name}.tar.xz") [
      "https://gstreamer.freedesktop.org/src/gstreamer-editing-services"
      "mirror://gnome/sources/gstreamer-editing-services/${channel}"
    ];
    hashOutput = false;
    inherit (source) sha256;
  };

  nativeBuildInputs = [
    flex
    meson
    ninja
  ];

  buildInputs = [
    glib
    gobject-introspection
    gst-plugins-base
    gstreamer
    libxml2
  ];

  mesonFlags = [
    "-Ddisable_introspection=false"
    "-Ddisable_gtkdoc=true"
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
        # Sebastian Dröge
        "7F4B C7CC 3CA0 6F97 336B  BFEB 0668 CC14 86C2 D7B5"
        # Tim-Philipp Müller
        "D637 032E 45B8 C658 5B94  5656 5D2E EE6F 6F34 9D7C"
      ];
      failEarly = true;
    };
  };

  meta = with lib; {
    description = "SDK for making video editors and more";
    homepage = http://gstreamer.freedesktop.org;
    license = licenses.lgpl2plus;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
