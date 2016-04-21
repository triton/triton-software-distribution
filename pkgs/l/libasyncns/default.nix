{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name = "libasyncns-0.8";

  src = fetchurl {
    url = "http://0pointer.de/lennart/projects/libasyncns/${name}.tar.gz";
    multihash = "QmXUe93maw3xPyEE8mQZrJFH3ZCtCc6uAwLdCztdYm5x5D";
    sha256 = "0x5b6lcic4cd7q0bx00x93kvpyzl7n2abbgvqbrlzrfb8vknc6jg";
  };

  meta = with stdenv.lib; {
    homepage = http://0pointer.de/lennart/projects/libasyncns/;
    description = "a C library for Linux/Unix for executing name service queries asynchronously";
    license = licenses.lgpl21;
    platforms = platforms.all;
    maintainers = with maintainers; [ wkennington ];
  };
}
