{ stdenv
, fetchurl
, gettext
, intltool

, gdk-pixbuf
, hicolor_icon_theme
}:

stdenv.mkDerivation rec {
  name = "adwaita-icon-theme-${version}";
  versionMajor = "3.20";
  #versionMinor = "0";
  version = "${versionMajor}"; #.${versionMinor}";

  src = fetchurl {
    url = "mirror://gnome/sources/adwaita-icon-theme/${versionMajor}/${name}.tar.xz";
    sha256 = "7a0a887349f340dd644032f89d81264b694c4b006bd51af1c2c368d431e7ae35";
  };

  configureFlags = [
    # nls creates unused directories
    "--disable-nls"
    "--enable-w32-cursors"
    "--disable-l-xl-variants"
  ];

  nativeBuildInputs = [
    gettext
    intltool
  ];

  propagatedBuildInputs = [
    # For convenience, we can specify adwaita-icon-theme only in packages
    hicolor_icon_theme
  ];

  buildInputs = [
    gdk-pixbuf
  ];

  doCheck = false;

  meta = with stdenv.lib; {
    description = "GNOME default icon theme";
    homepage = https://git.gnome.org/browse/adwaita-icon-theme/;
    license = licenses.lgpl3;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
