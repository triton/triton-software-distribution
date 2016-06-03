{ stdenv
, fetchurl

, libbsd
, ncurses
}:

stdenv.mkDerivation rec {
  name = "mg-20160421";

  src = fetchurl {
    url = "http://homepage.boetes.org/software/mg/${name}.tar.gz";
    sha256 = "16iswsirhdc8s9v7x1cpnazzryi55zr4ii484prz03warfz8zpdm";
  };

  buildInputs = [
    libbsd
    ncurses
  ];

  postPatch =
    /* Remove OpenBSD specific easter egg */ ''
      sed -i GNUmakefile \
        -e 's/theo\.o//'
      sed -i main.c \
        -e '/theo_init/d'
    '' + /* Remove hardcoded paths */ ''
      sed -i GNUmakefile \
        -e 's|/usr/bin/||'
    '' + /* Use ncurses instead of curses */ ''
      sed -i GNUmakefile \
        -e 's/curses/ncurses/'
    '';

  makefile = "GNUmakefile";

  makeFlags = [
    "prefix=$(out)"
  ];

  meta = with stdenv.lib; {
    description = "Micro GNU/emacs, an EMACS style editor";
    homepage = http://homepage.boetes.org/software/mg/;
    license = licenses.publicDomain;
    platforms = with platforms;
      x86_64-linux;
  };
}
