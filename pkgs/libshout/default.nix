{ stdenv
, fetchurl

, libogg
, libvorbis
, libtheora
, speex
}:

stdenv.mkDerivation rec {
  name = "libshout-2.4.1";

  src = fetchurl {
    url = "http://downloads.xiph.org/releases/libshout/${name}.tar.gz";
    sha256 = "0kgjpf8jkgyclw11nilxi8vyjk4s8878x23qyxnvybbgqbgbib7k";
  };

  buildInputs = [
    libogg
    libvorbis
    libtheora
    speex
  ];

  meta = with stdenv.lib; {
    description = "icecast 'c' language bindings";
    homepage = http://www.icecast.org;
    license = licenses.gpl2;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
