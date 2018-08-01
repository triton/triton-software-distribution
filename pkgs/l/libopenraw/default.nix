{ stdenv
, fetchurl
, lib

, boost
, gdk-pixbuf
, glib
, libjpeg
, libxml2
}:

let
  version = "0.1.3";
in
stdenv.mkDerivation rec {
  name = "libopenraw-${version}";

  src = fetchurl {
    url = "https://libopenraw.freedesktop.org/download/${name}.tar.bz2";
    multihash = "QmXYof3AAd1oBA8S5hU7MwroaTD8upr3cF444oT262zyKc";
    hashOutput = false;
    sha256 = "6405634f555849eb01cb028e2a63936e7b841151ea2a1571ac5b5b10431cfab9";
  };

  buildInputs = [
    boost
    gdk-pixbuf
    glib
    libjpeg
    libxml2
  ];

  postPatch = /* Fix loader hardcoded install path to not use gdk-pixbuf prefix */ ''
    sed -i configure{,.ac} \
      -e "s,GDK_PIXBUF_DIR=.*,GDK_PIXBUF_DIR=$out/${gdk-pixbuf.loadersCachePath}/loaders,"
  '';

  configureFlags = [
    "--disable-maintainer-mode"
  ];

  passthru = {
    srcVerification = fetchurl {
      inherit (src)
        outputHash
        outputHashAlgo
        urls;
      pgpsigUrls = map (n: "${n}.asc") src.urls;
      # Hubert Figuiere
      pgpKeyFingerprint = "6C44 DB3E 0BF3 EAF5 B433  239A 5FEE 05E6 A56E 15A3";
      failEarly = true;
    };
  };

  meta = with lib; {
    description = "RAW camerafile decoding library";
    homepage = https://libopenraw.freedesktop.org;
    license = licenses.lgpl3;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
