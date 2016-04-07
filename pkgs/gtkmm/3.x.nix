{ stdenv
, fetchurl

, atkmm
, cairomm
, gdk-pixbuf
, glibmm
, gtk3
, libepoxy
, pangomm
}:

let
  inherit (stdenv.lib)
    enFlag;
in

stdenv.mkDerivation rec {
  name = "gtkmm-${version}";
  versionMajor = "3.20";
  versionMinor = "0";
  version = "${versionMajor}.${versionMinor}";

  src = fetchurl {
    url = "mirror://gnome/sources/gtkmm/${versionMajor}/${name}.tar.xz";
    sha256 = "f021573f870df8a0b40ba37a7864c37be517c7a88cc957a193dbab28449b028a";
  };

  buildInputs = [
    atkmm
    cairomm
    gdk-pixbuf
    glibmm
    gtk3
    libepoxy
    pangomm
  ];

  configureFlags = [
    "--disable-maintainer-mode"
    "--disable-win32-backend"
    "--disable-quartz-backend"
    (enFlag "x11-backend" gtk3.x11_backend null)
    (enFlag "wayland-backend" gtk3.wayland_backend null)
    (enFlag "broadway-backend" gtk3.broadway_backend null)
    (enFlag "api-atkmm" (atkmm != null) null)
    # Requires deprecated api to build
    "--enable-deprecated-api"
    "--disable-documentation"
    "--enable-warnings"
    "--without-libstdc-doc"
    "--without-libsigc-doc"
    "--without-glibmm-doc"
    "--without-cairomm-doc"
    "--without-pangomm-doc"
    "--without-atkmm-doc"
  ];

  meta = with stdenv.lib; {
    description = "C++ interface for GTK+";
    homepage = http://gtkmm.org/;
    license = licenses.lgpl2Plus;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
