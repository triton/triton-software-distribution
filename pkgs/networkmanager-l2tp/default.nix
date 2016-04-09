{ stdenv
, autoconf
, automake
, fetchFromGitHub
, fetchTritonPatch
, gettext
, intltool
, libtool

, dbus-glib
, glib
, gtk3
, libgnome-keyring
, networkmanager
, ppp
, strongswan
, xl2tpd
}:

let
  inherit (stdenv.lib)
    wtFlag;
in

stdenv.mkDerivation rec {
  name = "NetworkManager-l2tp-${version}";
  version = "0.9.8.7";

  src = fetchFromGitHub {
    owner = "seriyps";
    repo = "NetworkManager-l2tp";
    rev = version;
    sha256 = "be0fd7f43f7278b6f6482b75429f1da9f4be95ad7429837a492432da83b16dde";
  };

  nativeBuildInputs = [
    automake
    autoconf
    gettext
    intltool
    libtool
  ];

  buildInputs = [
    dbus-glib
    glib
    gtk3
    libgnome-keyring
    networkmanager
    ppp
  ];

  patches = [
    (fetchTritonPatch {
      rev = "d3fc5e59bd2b4b465c2652aae5e7428b24eb5669";
      file = "networkmanager/l2tp-purity.patch";
      sha256 = "e170efd7f3d96c61898a79569b570c435d8503a9ae021ed820feba1c82cb4089";
    })
  ];

  preConfigure =
    /* upstrem autogen.sh enables maintainer mode */ ''
      autoreconf --install --symlink
      intltoolize --force
      autoreconf
    '';

  configureFlags = [
    "--disable-maintainer-mode"
    "--enable-nls"
    "--enable-more-warnings"
    #"--with-pppd-plugin-dir"
    (wtFlag "gnome" (
      gtk3 != null
      && libgnome-keyring != null) null)
  ];

  postConfigure = ''
    sed -i Makefile */Makefile \
      -e 's/-Werror//g'
  '';

  meta = with stdenv.lib; {
    description = "L2TP plugin for NetworkManager";
    homepage = https://github.com/seriyps/NetworkManager-l2tp;
    license = licenses.gpl2;
    maintainers = with maintainers; [ ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}
