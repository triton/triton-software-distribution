{ stdenv
, docbook_xsl
, fetchurl
, libxslt

, libdrm
, libtsm
, libxkbcommon
, mesa
, pango
, pixman
, systemd_lib
}:

stdenv.mkDerivation rec {
  name = "kmscon-8";

  src = fetchurl {
    url = "http://www.freedesktop.org/software/kmscon/releases/${name}.tar.xz";
    sha256 = "0axfwrp3c8f4gb67ap2sqnkn75idpiw09s35wwn6kgagvhf1rc0a";
  };

  nativeBuildInputs = [
    docbook_xsl
    libxslt
  ];

  buildInputs = [
    libdrm
    libtsm
    libxkbcommon
    mesa
    pango
    pixman
    systemd_lib
  ];

  # Don't depend on old systemd compat libs
  preConfigure = ''
    sed -i 's,libsystemd-[a-zA-Z]*,libsystemd,g' configure
  '';

  configureFlags = [
    "--enable-multi-seat"
    "--disable-debug"
    "--enable-optimizations"
    "--with-renderers=bbulk,gltex,pixman"
  ];

  meta = {
    description = "KMS/DRM based System Console";
    homepage = "http://www.freedesktop.org/wiki/Software/kmscon/";
    license = stdenv.lib.licenses.mit;
    platforms = stdenv.lib.platforms.linux;
  };
}
