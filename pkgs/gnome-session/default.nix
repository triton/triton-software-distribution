{ stdenv
, fetchurl
, gettext
, intltool

, adwaita-icon-theme
, gdk-pixbuf
, glib
, gnome-desktop
, gnome-settings-daemon
, gsettings-desktop-schemas
, gtk3
, json-glib
, mesa_noglu
, systemd
, upower
, xorg
}:

with {
  inherit (stdenv.lib)
    enFlag;
};

stdenv.mkDerivation rec {
  name = "gnome-session-${version}";
  versionMajor = "3.18";
  versionMinor = "1.2";
  version = "${versionMajor}.${versionMinor}";

  src = fetchurl {
    url = "mirror://gnome/sources/gnome-session/${versionMajor}/${name}.tar.xz";
    sha256 = "b37d823d57ff2e3057401a426279954699cfe1e44e59a4cbdd941687ff928a45";
  };

  nativeBuildInputs = [
    gettext
    intltool
  ];

  buildInputs = [
    adwaita-icon-theme
    gdk-pixbuf
    glib
    gnome-desktop
    gnome-settings-daemon
    gsettings-desktop-schemas
    gtk3
    json-glib
    mesa_noglu
    systemd
    upower
    xorg.libICE
    xorg.libSM
    xorg.libX11
    xorg.libXau
    xorg.libXcomposite
    xorg.libXext
    xorg.libXrender
    xorg.libXtst
    xorg.xtrans
  ];

  configureFlags = [
    "--disable-maintainer-mode"
    "--enable-compile-warnings"
    "--disable-iso-c"
    "--enable-deprecation-flags"
    "--enable-session-selector"
    "--disable-gconf"
    (enFlag "systemd" (systemd != null) null)
    "--disable-consolekit"
    "--disable-docbook-docs"
    "--disable-man"
    "--enable-nls"
    "--enable-schemas-compile"
    "--enable-ipv6"
    "--with-xtrans"
  ];

  meta = with stdenv.lib; {
    description = "Gnome session manager";
    homepage = https://git.gnome.org/browse/gnome-session;
    license = with licenses; [
      fdl11
      gpl2
      lgpl2
    ];
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = [
      "i686-linux"
      "x86_64-linux"
    ];
  };

}
