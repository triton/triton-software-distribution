{ stdenv
, fetchurl
, gettext
#, gtk-doc
, lib

, glib
, gobject-introspection
, iso-codes
, libxml2
, vala
, xorg
}:

let
  inherit (lib)
    boolEn;
in
stdenv.mkDerivation rec {
  name = "libxklavier-5.4";

  src = fetchurl rec {
    url = "http://pkgs.fedoraproject.org/repo/pkgs/libxklavier/${name}.tar.bz2/${md5Confirm}/${name}.tar.bz2";
    multihash = "QmNdE3S2pGqMgj7vkNg8XwMxKiws8zfupnm3FnpXGnEQc8";
    md5Confirm = "13af74dcb6011ecedf1e3ed122bd31fa";
    sha256 = "17a34194df5cbcd3b7bfd0f561d95d1f723aa1c87fca56bc2c209514460a9320";
  };

  nativeBuildInputs = [
    gettext
    #gtk-doc
    vala
  ];

  buildInputs = [
    glib
    gobject-introspection
    iso-codes
    libxml2
    xorg.libX11
    xorg.libXi
    xorg.libxkbfile
    xorg.xkbcomp
    xorg.xkeyboardconfig
  ];

  configureFlags = [
    "--disable-maintainer-mode"
    "--enable-rpath"
    "--enable-nls"
    "--${boolEn (gobject-introspection != null)}-introspection"
    "--${boolEn (vala != null)}-vala"
    "--disable-gtk-doc"
    "--disable-gtk-doc-html"
    "--disable-gtk-doc-pdf"
    "--${boolEn (xorg.libxkbfile != null)}-xkb-support"
    "--enable-xmodmap-support"
  ];

  meta = with lib; {
    description = "Library providing high-level API for X Keyboard Extension known as XKB";
    homepage = http://freedesktop.org/wiki/Software/LibXklavier;
    license = licenses.lgpl2Plus;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
