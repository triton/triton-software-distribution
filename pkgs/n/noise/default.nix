{ stdenv
, cmake
, fetchFromGitHub
, gettext
, intltool
, lib
, makeWrapper

, adwaita-icon-theme
, dbus-glib
, dconf
, gdk-pixbuf
, glib
, gobject-introspection
, granite
, gsettings-desktop-schemas
, gst-plugins-bad
, gst-plugins-base
, gst-plugins-good
, gst-plugins-ugly
, gstreamer
, gtk3
, json-glib
, libaccounts-glib
#, libdbusmenu
, libgda
, libgee
, libgpod
#, libindicate
, libnotify
, libpeas
, librsvg
, libsoup
, libxml2
, shared-mime-info
, taglib
, vala
, zeitgeist

, atk
, cairo
, pango
}:

let
  inherit (lib)
    makeSearchPath;

  channel = "0.4";
  version = "${channel}.0.3";
in
stdenv.mkDerivation rec {
  name = "noise-${version}";

  src = fetchFromGitHub {
    version = 3;
    owner = "elementary";
    repo = "music";
    rev = "${version}";
    sha256 = "0f89b9311f367b1c1c3c99b59130a28bf4ff52750a4ee4ab47f3cde5ca4cd9e5";
  };

  nativeBuildInputs = [
    cmake
    gettext
    intltool
    makeWrapper
  ];

  buildInputs = [
    adwaita-icon-theme
    dbus-glib
    dconf
    gdk-pixbuf
    glib
    gobject-introspection
    granite
    gsettings-desktop-schemas
    gst-plugins-bad
    gst-plugins-base
    gst-plugins-good
    gst-plugins-ugly
    gstreamer
    gtk3
    json-glib
    libaccounts-glib
    #libdbusmenu
    libgda
    libgee
    libgpod
    #libindicate
    libnotify
    libpeas
    libsoup
    libxml2
    shared-mime-info
    taglib
    vala
    zeitgeist
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DBUILD_FOR_ELEMENTARY=OFF"
    "-DBUILD_PLUGINS=ON"
    "-DICON_UPDATE=OFF"
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=OFF"
    "-DVALA_EXECUTABLE=${vala}/bin/valac"
  ];

  preFixup = ''
    wrapProgram $out/bin/noise \
      --set 'GDK_PIXBUF_MODULE_FILE' "$GDK_PIXBUF_MODULE_FILE" \
      --set 'GSETTINGS_BACKEND' 'dconf' \
      --set 'GI_TYPELIB_PATH' "$GI_TYPELIB_PATH" \
      --prefix 'GIO_EXTRA_MODULES' : "$GIO_EXTRA_MODULES" \
      --prefix 'GST_PLUGIN_PATH' : "$GST_PLUGIN_PATH" \
      --prefix 'XDG_DATA_DIRS' : "$out/share" \
      --prefix 'XDG_DATA_DIRS' : "$GSETTINGS_SCHEMAS_PATH" \
      --prefix 'XDG_DATA_DIRS' : "${shared-mime-info}/share" \
      --prefix 'XDG_DATA_DIRS' : "$XDG_ICON_DIRS"
  '';

  meta = with lib; {
    description = "Music player for Elementary OS";
    homepage = https://github.com/elementary/music;
    license = licenses.gpl3;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
