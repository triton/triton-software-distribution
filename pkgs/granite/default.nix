{ stdenv
, fetchurl
, cmake
, gettext
, perl

, atk
, cairo
, gdk-pixbuf
, glib
, gobject-introspection
, gtk3
, hicolor-icon-theme
, libgee
, pango
, vala
}:

let
  channel = "0.4";
  version = "${channel}";
in

stdenv.mkDerivation rec {
  name = "granite-${version}";

  src = fetchurl {
    url = "https://launchpad.net/granite/${channel}/loki-alpha1/"
      + "+download/${name}.tar.xz";
    sha256 = "73066f393d4c0aa637046e6fa0d6130a2612f277b9e493366f2f99267d85c5d9";
  };

  nativeBuildInputs = [
    cmake
    gettext
    perl
  ];

  buildInputs = [
    atk
    cairo
    gdk-pixbuf
    glib
    libgee
    gobject-introspection
    gtk3
    hicolor-icon-theme
    pango
    vala
  ];

  preConfigure = ''
    cmakeFlagsArray=(
      "-DINTROSPECTION_GIRDIR=$out/share/gir-1.0/"
      "-DINTROSPECTION_TYPELIBDIR=$out/lib/girepository-1.0"
    )
  '';

  meta = with stdenv.lib; {
    description = "An extension to GTK+ used by elementary OS";
    homepage = https://launchpad.net/granite;
    license = licenses.lgpl3;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
