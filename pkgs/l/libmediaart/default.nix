{ stdenv
, fetchurl
, lib
, meson
, ninja

, glib
, gdk-pixbuf
, gobject-introspection
, vala
, zlib
}:

let
  versionMajor = "1.9";
  versionMinor = "4";
  version = "${versionMajor}.${versionMinor}";
in
stdenv.mkDerivation rec {
  name = "libmediaart-${version}";

  src = fetchurl {
    url = "mirror://gnome/sources/libmediaart/${versionMajor}/${name}.tar.xz";
    hashOutput = false;
    sha256 = "a57be017257e4815389afe4f58fdacb6a50e74fd185452b23a652ee56b04813d";
  };

  nativeBuildInputs = [
    meson
    ninja
    #vala
  ];

  buildInputs = [
    gdk-pixbuf
    glib
    gobject-introspection
    zlib
  ];

  postPatch = ''
    # Remove broken meson vala binding generator
    sed -i libmediaart/meson.build \
      -e '/libmediaart_vapi/,+3d'
  '';

  mesonFlags = [
    "-Dimage_library=gdk-pixbuf"
    "-Dwith-docs=no"
  ];

  passthru = {
    srcVerification = fetchurl {
      inherit (src)
        outputHash
        outputHashAlgo
        urls;
      sha256Url = "https://download.gnome.org/sources/libmediaart/${versionMajor}/"
        + "${name}.sha256sum";
      failEarly = true;
    };
  };

  meta = with lib; {
    description = "Manages, extracts and handles media art caches";
    homepage = https://github.com/GNOME/libmediaart;
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
