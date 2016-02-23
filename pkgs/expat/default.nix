{ stdenv
, fetchurl
}:

stdenv.mkDerivation rec {
  name = "expat-2.1.0";

  src = fetchurl {
    url = "mirror://sourceforge/expat/${name}.tar.gz";
    sha256 = "11pblz61zyxh68s5pdcbhc30ha1b2vfjd83aiwfg4vc15x3hadw2";
  };

  patches = [
    ./CVE-2015-1283.patch
  ];

  meta = with stdenv.lib; {
    homepage = http://www.libexpat.org/;
    description = "A stream-oriented XML parser library written in C";
    license = licenses.mit;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}
