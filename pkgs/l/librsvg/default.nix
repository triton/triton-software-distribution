{ stdenv
, fetchurl
, lib

, bzip2
, cairo
, gdk-pixbuf_unwrapped
, glib
, gobject-introspection
, libcroco
, libgsf
, libxml2
, pango
, vala
}:

let
  inherit (lib)
    boolEn;

  versionMajor = "2.40";
  versionMinor = "17";
  version = "${versionMajor}.${versionMinor}";
in
stdenv.mkDerivation rec {
  name = "librsvg-${version}";

  src = fetchurl {
    url = "mirror://gnome/sources/librsvg/${versionMajor}/${name}.tar.xz";
    hashOutput = false;
    sha256 = "e6f6c5cbecc405bb945c7cd15061276035ae3173bbb3bb25e8a916779c7f69cc";
  };

  buildInputs = [
    bzip2
    cairo
    gdk-pixbuf_unwrapped
    glib
    gobject-introspection
    libcroco
    libgsf
    libxml2
    pango
    vala
  ];

  configureFlags = [
    "--disable-maintainer-mode"
    "--enable-pixbuf-loader"
    "--enable-Bsymbolic"
    "--disable-gtk-doc"
    "--disable-gtk-doc-html"
    "--disable-gtk-doc-pdf"
    "--disable-tools"
    "--${boolEn (gobject-introspection != null)}-introspection"
    "--${boolEn (vala != null)}-vala"
  ];

  # It wants to add loaders and update the loaders.cache in gdk-pixbuf
  # Patching the Makefiles so it creates rsvg specific loaders and the
  # relevant loader.cache here.
  postConfigure = ''
    GDK_PIXBUF=$out/lib/gdk-pixbuf-2.0/2.10.0
    mkdir -p $GDK_PIXBUF/loaders
    sed -i gdk-pixbuf-loader/Makefile \
      -e "s#gdk_pixbuf_moduledir = .*#gdk_pixbuf_moduledir = $GDK_PIXBUF/loaders#" \
      -e "s#gdk_pixbuf_cache_file = .*#gdk_pixbuf_cache_file = $GDK_PIXBUF/loaders.cache#" \
      -e "s#\$(GDK_PIXBUF_QUERYLOADERS)#GDK_PIXBUF_MODULEDIR=$GDK_PIXBUF/loaders \$(GDK_PIXBUF_QUERYLOADERS)#"
  '';

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      sha256Url = "https://download.gnome.org/sources/librsvg/2.40/${name}.sha256sum";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with lib; {
    description = "Scalable Vector Graphics (SVG) rendering library";
    homepage = https://wiki.gnome.org/Projects/LibRsvg;
    license = licenses.lgpl2;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
