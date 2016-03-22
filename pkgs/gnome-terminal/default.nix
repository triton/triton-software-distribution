{ stdenv
, desktop_file_utils
, fetchurl
, gnome_doc_utils
, intltool
, itstool
, libxml2
, makeWrapper
, util-linux_lib
, which

, adwaita-icon-theme
, appdata-tools
, dconf
, gdk-pixbuf
, glib
, gsettings-desktop-schemas
, gtk3
, nautilus
, vala
, vte
, xorg
}:

stdenv.mkDerivation rec {
  name = "gnome-terminal-${version}";
  versionMajor = "3.20";
  versionMinor = "0";
  version = "${versionMajor}.${versionMinor}";

  src = fetchurl {
    url = "mirror://gnome/sources/gnome-terminal/${versionMajor}/${name}.tar.xz";
    sha256 = "2fe7f6bd3ca4e93ce156f83e673b9e8c3f0155b6bc603e109edc942718eb4150";
  };

  nativeBuildInputs = [
    desktop_file_utils
    gnome_doc_utils
    intltool
    itstool
    libxml2
    makeWrapper
    util-linux_lib
    which
  ];

  buildInputs = [
    adwaita-icon-theme
    appdata-tools
    dconf
    gdk-pixbuf
    glib
    gsettings-desktop-schemas
    gtk3
    nautilus
    vala
    vte
    xorg.libX11
  ];

  configureFlags = [
    "--disable-search-provider"
    "--disable-migration"
  ];

  preFixup = ''
    wrapProgram $out/libexec/gnome-terminal-server \
      --set 'GDK_PIXBUF_MODULE_FILE' "$GDK_PIXBUF_MODULE_FILE" \
      --set 'GSETTINGS_BACKEND' 'dconf' \
      --prefix 'GIO_EXTRA_MODULES' : "$GIO_EXTRA_MODULES" \
      --prefix 'XDG_DATA_DIRS' : "$GSETTINGS_SCHEMAS_PATH" \
      --prefix 'XDG_DATA_DIRS' : "$out/share" \
      --prefix 'XDG_DATA_DIRS' : "$XDG_ICON_DIRS"
  '';

  meta = with stdenv.lib; {
    description = "The Gnome Terminal";
    homepage = https://wiki.gnome.org/Apps/Terminal/;
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
