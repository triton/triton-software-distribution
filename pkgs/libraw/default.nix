{ stdenv
, fetchurl

, lcms2
, jasper
}:

stdenv.mkDerivation rec {
  name = "libraw-${version}";
  version = "0.17.1";

  src = fetchurl {
    url = "http://www.libraw.org/data/LibRaw-${version}.tar.gz";
    sha256 = "18fygk896gxbx47nh2rn5jp4skisgkl6pdfjqb7h0zn39hd6b6g5";
  };

  buildInputs = [
    lcms2
    jasper
  ];

  meta = with stdenv.lib; {
    description = "Library for reading RAW files obtained from digital photo cameras (CRW/CR2, NEF, RAF, DNG, and others)";
    homepage = http://www.libraw.org/;
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}

