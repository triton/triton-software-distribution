{ stdenv
, fetchurl
, m4
, perl
}:

stdenv.mkDerivation rec {
  name = "bison-3.0.4";

  src = fetchurl {
    url = "mirror://gnu/bison/${name}.tar.gz";
    sha256 = "b67fd2daae7a64b5ba862c66c07c1addb9e6b1b05c5f2049392cfd8a2172952e";
  };

  nativeBuildInputs = [
    m4
    perl
  ];

  # We need this for bison to work correctly when being
  # used during the build process
  propagatedBuildInputs = [
    m4
  ];

  meta = with stdenv.lib; {
    description = "Yacc-compatible parser generator";
    homepage = "http://www.gnu.org/software/bison/";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}
