{ stdenv
, fetchurl
, intltool
, lib
, makeWrapper

, atk
, dbus
, dconf
, gconf
, glib
, gobject-introspection
, gtk2
, gtk3
, iso-codes
, json-glib
, libnotify
, libx11
, libxext
, libxfixes
, libxi
, libxkbcommon
, python3Packages
, vala
, wayland
, xorg
}:

let
  inherit (lib)
    boolEn;

  version = "1.5.17";
in
stdenv.mkDerivation rec {
  name = "ibus-${version}";

  src = fetchurl {
    url = "https://github.com/ibus/ibus/releases/download/${version}/"
      + "${name}.tar.gz";
    sha256 = "0347a8055977ca458e8add750af5f9b76e1a524844cc3b0e2fad70ce153dd219";
  };

  nativeBuildInputs = [
    intltool
    makeWrapper
    vala
  ];

  buildInputs = [
    glib
    dbus
    dconf
    gconf
    gobject-introspection
    gtk2
    gtk3
    iso-codes
    json-glib
    libnotify
    libx11
    libxext
    libxfixes
    libxi
    libxkbcommon
    python3Packages.python
    wayland
  ];

  configureFlags = [
    "--disable-maintainer-mode"
    "--enable-nls"
    "--enable-glibtest"
    "--disable-tests"
    "--${boolEn (gtk2 != null)}-gtk2"
    "--${boolEn (gtk3 != null)}-gtk3"
    "--enable-xim"
    "--${boolEn (wayland != null)}-wayland"
    "--enable-appindicator"
    "--${boolEn (gobject-introspection != null)}-introspection"
    "--${boolEn (vala != null)}-vala"
    "--disable-gtk-doc"
    "--disable-gtk-doc-html"
    "--disable-gtk-doc-pdf"
    "--disable-gconf"
    "--enable-schemas-install"
    "--disable-memconf"
    "--${boolEn (dconf != null)}-dconf"
    "--disable-schemas-compile"
    "--${boolEn (python3Packages.python != null)}-python-library"
    "--enable-setup"
    "--${boolEn (python3Packages.python != null)}-dbus-python-check"
    "--enable-key-snooper"
    "--enable-surrounding-text"
    "--enable-ui"
    "--enable-engine"
    "--enable-libnotify"
    "--disable-emoji-dict"
    "--with-python=${python3Packages.python.interpreter}"
  ];

  preConfigure = ''
    sed -i data/dconf/Makefile.in \
      -e 's/dconf update/echo/'
    sed -i configure \
      -e "s|PYTHON2_LIBDIR=.*|PYTHON2_LIBDIR=$out/lib/${
        python3Packages.python.libPrefix}|"
  '';

  preFixup = ''
    for f in "$out"/bin/* ; do
      wrapProgram "$f" \
        --prefix XDG_DATA_DIRS : "$out/share:$GSETTINGS_SCHEMAS_PATH" \
        --prefix PYTHONPATH : "$(toPythonPath ${python3Packages.pygobject})" \
        --prefix LD_LIBRARY_PATH : "${gtk3}/lib:${atk}/lib:$out/lib" \
        --prefix GI_TYPELIB_PATH : "$GI_TYPELIB_PATH:$out/lib/girepository-1.0" \
        --prefix GIO_EXTRA_MODULES : "${dconf}/lib/gio/modules"
    done
  '';

  meta = with lib; {
    description = "Intelligent Input Bus for Linux / Unix OS";
    homepage = https://github.com/ibus/ibus/wiki;
    license = licenses.lgpl21;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
