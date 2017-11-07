{ stdenv
, fetchurl
, libtool

, glib
, gobject-introspection
, libcanberra
, vala
}:

let
  inherit (stdenv.lib)
    enFlag;
in

stdenv.mkDerivation rec {
  name = "gsound-${version}";
  versionMajor = "1.0";
  versionMinor = "2";
  version = "${versionMajor}.${versionMinor}";

  src = fetchurl {
    url = "mirror://gnome/sources/gsound/${versionMajor}/${name}.tar.xz";
    sha256 = "0lwfwx2c99qrp08pfaj59pks5dphsnxjgrxyadz065d8xqqgza5v";
  };

  nativeBuildInputs = [
    libtool
    vala
  ];

  buildInputs = [
    glib
    gobject-introspection
    libcanberra
  ];

  configureFlags = [
    "--disable-maintainer-mode"
    "--enable-compile-warnings"
    "--disable-Werror"
    "--disable-gtk-doc"
    "--disable-gtk-doc-html"
    "--disable-gtk-doc-pdf"
    (enFlag "introspection" (gobject-introspection != null) null)
    (enFlag "vala" (vala != null) null)
  ];

  meta = with stdenv.lib; {
    description = "GObject wrapper around the libcanberra sound event library";
    homepage = https://wiki.gnome.org/Projects/GSound;
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
