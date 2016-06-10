{ stdenv
, fetchurl
, flex
, gettext
, libtool

, gd
, libexif
, libjpeg-turbo_1-4
#, libltdl
, libusb
, libxml2
#, lockdev
}:

let
  inherit (stdenv.lib)
    wtFlag;
in

stdenv.mkDerivation rec {
  name = "libgphoto2-2.5.9";

  src = fetchurl {
    url = "mirror://sourceforge/gphoto/${name}.tar.bz2";
    sha256 = "0chz57rhzdz1cbdjw1q5rs439s879kk06jrci4jyn5rlm7iyic6d";
  };

  nativeBuildInputs = [
    flex
    gettext
    libtool
  ];

  buildInputs = [
    gd
    libexif
    libjpeg-turbo_1-4
    libusb
    libxml2
    #lockdev
  ];

  configureFlags = [
    "--disable-gp2ddb"
    "--enable-nls"
    "--enable-rpath"
    "--enable-largefile"
    "--disable-internal-docs"
    "--disable-docs"
    (wtFlag "jpeg" (libjpeg-turbo_1-4 != null) null)
    "--with-camlibs=all"
  ];

  meta = with stdenv.lib; {
    description = "A library for accessing digital cameras";
    homepage = http://www.gphoto.org/proj/libgphoto2/;
    license = licenses.gpl2;
    maintainers = with maintainers; [ ];
    platforms = with platforms;
      x86_64-linux;
  };
}
