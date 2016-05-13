{ stdenv
, autoconf
, autoconf-archive
, automake
, fetchFromGitHub
, gettext
, intltool
, libtool
, makeWrapper
, pkgconfig

, adwaita-icon-theme
, appstream-glib
, dconf
, gdk-pixbuf
, glib
, gtk3
, libepoxy
, librsvg
, mpv
, python2Packages
, wayland
, xorg
}:

let
  inherit (stdenv.lib)
    enFlag;
in

stdenv.mkDerivation rec {
  name = "gnome-mpv-${version}";
  version = "2016-05-13";

  src = fetchFromGitHub {
    owner = "gnome-mpv";
    repo = "gnome-mpv";
    rev = "25331500ae54c7ec94bd9ac954125ae025219378";
    sha256 = "2466643dae3c56dd33f7487375e014f07326a43d083349e5da0533ec07738fbb";
  };

  nativeBuildInputs = [
    autoconf
    autoconf-archive
    automake
    dconf
    gettext
    intltool
    libtool
    makeWrapper
    pkgconfig
  ];

  buildInputs = [
    adwaita-icon-theme
    appstream-glib
    gdk-pixbuf
    glib
    gtk3
    libepoxy
    librsvg
    mpv
    python2Packages.youtube-dl
    wayland
    xorg.libX11
  ];

  preConfigure =
    /* Ignore autogen.sh and run the commands manually */ ''
      aclocal --install -I m4
      intltoolize --copy --automake
      autoreconf --install -Wno-portability
    '';

  configureFlags = [
    "--disable-maintainer-mode"
    "--enable-nls"
    "--enable-schemas-compile"
    "--disable-debug"
    "--enable-opencl-cb"
    (enFlag "appstream-util" (appstream-glib != null) null)
  ];

  preFixup = ''
    wrapProgram $out/bin/gnome-mpv  \
      --set 'GDK_PIXBUF_MODULE_FILE' "$GDK_PIXBUF_MODULE_FILE" \
      --prefix 'GIO_EXTRA_MODULES' : "$GIO_EXTRA_MODULES" \
      --prefix 'XDG_DATA_DIRS' : "$GSETTINGS_SCHEMAS_PATH" \
      --prefix 'XDG_DATA_DIRS' : "$out/share" \
      --prefix 'XDG_DATA_DIRS' : "$XDG_ICON_DIRS"
  '';

  meta = with stdenv.lib; {
    description = "A simple GTK+ frontend for mpv";
    homepage = https://github.com/gnome-mpv/gnome-mpv;
    license = licenses.gpl3;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}