{ stdenv
, fetchTritonPatch
, fetchurl
, gettext
, intltool

, atk
, cairo
, gdk-pixbuf
, glib
, gtk
, pango
, libxml2
, perl
, gobject-introspection
, vala

, channel
}:

let
  inherit (stdenv.lib)
    boolEn;

  source = (import ./sources.nix { })."${channel}";
in
stdenv.mkDerivation rec {
  name = "gtksourceview-${source.version}";

  src = fetchurl {
    url = "mirror://gnome/sources/gtksourceview/${channel}/${name}.tar.xz";
    hashOutput = false;
    inherit (source) sha256;
  };

  nativeBuildInputs = [
    gettext
    intltool
  ];

  buildInputs = [
    atk
    cairo
    gdk-pixbuf
    glib
    gtk
    pango
    libxml2
    perl
    gobject-introspection
    vala
  ];

  patches = [
    (fetchTritonPatch {
      rev = "453aedffa95d1c459a15a6f1fb8cb9d0ce810803";
      file = "gtksourceview/nix_share_path.patch";
      sha256 = "522655ce1664afef805040f2068094fdf57e3283a4cc2bdf52b33cb6de9fbe00";
    })
  ];

  configureFlags = [
    "--disable-maintainer-mode"
    "--enable-compile-warnings"
    "--enable-Werror"
    "--enable-deprecations"
    "--enable-completion-providers"
    "--disable-glade-catalog"
    "--enable-nls"
    "--enable-rpath"
    "--disable-gtk-doc"
    "--disable-gtk-doc-html"
    "--disable-gtk-doc-pdf"
    "--disable-installed-tests"
    "--${boolEn (gobject-introspection != null)}-introspection"
    "--disable-code-coverage"
    "--${boolEn (vala != null)}-vala"
  ];

  preBuild = ''
    sed -i gtksourceview/gtksourceview-utils.c \
      -e "s,@NIX_SHARE_PATH@,$out/share,"
  '';

  passthru = {
    srcVerification = fetchurl {
      inherit (src)
        outputHash
        outputHashAlgo
        urls;
      sha256Url = "https://download.gnome.org/sources/gtksourceview/"
        + "${channel}/${name}.sha256sum";
      failEarly = true;
    };
  };

  meta = with stdenv.lib; {
    description = "A text widget for syntax highlighting and other features";
    homepage = https://wiki.gnome.org/Projects/GtkSourceView;
    license = with licenses; [
      gpl2Plus
      lgpl21Plus
    ];
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
