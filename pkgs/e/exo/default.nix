{ stdenv
, fetchurl
, intltool
, lib
, makeWrapper

, glib
, gnome-themes-standard
, gtk_2
, libx11
, libxfce4ui
, libxfce4util
, perlPackages
, shared-mime-info
, xproto
}:

let
  inherit (lib)
    boolEn;

  channel = "0.10";
  version = "${channel}.7";
in
stdenv.mkDerivation rec {
  name = "exo-${version}";

  src = fetchurl {
    url = "http://archive.xfce.org/src/xfce/exo/${channel}/${name}.tar.bz2";
    multihash = "Qmc1A3VwqurTNFYTfCXm4hd4iC7VCekBAheiWkeCB1Fe2u";
    sha256 = "521581481128af93e815f9690020998181f947ac9e9c2b232b1f144d76b1b35c";
  };

  nativeBuildInputs = [
    intltool
    makeWrapper
  ];

  buildInputs = [
    glib
    gnome-themes-standard
    gtk_2
    libx11
    libxfce4ui
    libxfce4util
    perlPackages.URI
    xproto
  ];

  configureFlags = [
    "--disable-maintainer-mode"
    "--enable-nls"
    "--${boolEn (glib != null)}-gio-unix"
    "--disable-gtk-doc"
    "--disable-gtk-doc-html"
    "--disable-gtk-doc-pdf"
    "--disable-debug"
    #"--disable-linker-opts"
    #"--disable-visibility"
    "--with-x"
  ];

  preFixup = ''
    wrapProgram $out/bin/exo-desktop-item-edit \
      --prefix 'XDG_DATA_DIRS' : "${shared-mime-info}/share" \
      --run "$DEFAULT_GTK2_RC_FILES"
    wrapProgram $out/bin/exo-preferred-applications \
      --prefix 'XDG_DATA_DIRS' : "${shared-mime-info}/share" \
      --run "$DEFAULT_GTK2_RC_FILES"
  '';

  meta = with lib; {
    description = "Extensions to Xfce by os-cillation";
    homepage = http://www.xfce.org/;
    license = with licenses; [
      gpl2
      lgpl2
    ];
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
