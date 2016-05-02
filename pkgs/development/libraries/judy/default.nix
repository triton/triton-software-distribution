{ stdenv
, fetchurl
}:

stdenv.mkDerivation rec {
  name = "judy-${version}";
  version = "1.0.5";

  src = fetchurl {
    urls = [
      "mirror://gentoo/distfiles/Judy-${version}.tar.gz"
      "mirror://sourceforge/judy/Judy-${version}.tar.gz"
    ];
    sha256 = "1sv3990vsx8hrza1mvq3bhvv9m6ff08y4yz7swn6znszz24l0w6j";
  };

  # gcc 4.8 optimisations break judy.
  # http://sourceforge.net/p/judy/mailman/message/31995144/
  preConfigure = stdenv.lib.optionalString stdenv.cc.isGNU ''
    configureFlagsArray+=("CFLAGS=-fno-strict-aliasing -fno-aggressive-loop-optimizations")
  '';

  # Fails for 1.0.5
  parallelBuild = false;

  meta = {
    homepage = http://judy.sourceforge.net/;
    license = stdenv.lib.licenses.lgpl21Plus;
    description = "State-of-the-art C library that implements a sparse dynamic array";
  };
}
