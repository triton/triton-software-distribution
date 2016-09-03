{ stdenv
, fetchurl
, file
, intltool
, makeWrapper

, glib
, gtk3
, libxklavier
, xorg
}:

stdenv.mkDerivation rec {
  name = "libgnomekbd-3.6.0";

  src = fetchurl {
    url = "mirror://gnome-insecure/sources/libgnomekbd/3.6/${name}.tar.xz";
    sha256 = "c41ea5b0f64da470925ba09f9f1b46b26b82d4e433e594b2c71eab3da8856a09";
  };

  nativeBuildInputs = [
    intltool
    makeWrapper
  ];

  buildInputs = [
    glib
    gtk3
    libxklavier
    xorg.libX11
  ];

  preFixup = ''
    wrapProgram $out/bin/gkbd-keyboard-display \
      --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
  '';

  meta = with stdenv.lib; {
    description = "Keyboard management library";
    #maintainers = gnome3.maintainers;
    license = licenses.gpl2;
    platforms = with platforms;
      x86_64-linux;
  };
}
