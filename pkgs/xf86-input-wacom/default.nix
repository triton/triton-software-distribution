{ stdenv
, fetchurl

, file
, ncurses
, systemd_lib
, pixman
, xorg
}:

stdenv.mkDerivation rec {
  name = "xf86-input-wacom-0.33.0";

  src = fetchurl {
    url = "mirror://sourceforge/linuxwacom/${name}.tar.bz2";
    sha256 = "24eef830744a388795a318ef743f19c451e394d9ef1332e98e2d54810a70f8e0";
  };

  buildInputs = [
    ncurses
    pixman
    systemd_lib
    xorg.inputproto
    xorg.kbproto
    xorg.libX11
    xorg.libXext
    xorg.libXi
    xorg.libXinerama
    xorg.libXrandr
    xorg.libXrender
    xorg.randrproto
    xorg.xorgserver
    xorg.xproto
  ];

  preConfigure = ''
    mkdir -pv $out/share/X11/xorg.conf.d
    configureFlagsArray+=(
      "--with-xorg-module-dir=$out/lib/xorg/modules"
      "--with-sdkdir=$out/include/xorg"
      "--with-xorg-conf-dir=$out/share/X11/xorg.conf.d"
    )
  '';

  meta = with stdenv.lib; {
    description = "Wacom digitizer driver for X11";
    homepage = http://linuxwacom.sourceforge.net;
    license = licenses.gpl2;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
