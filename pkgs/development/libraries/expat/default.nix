{stdenv, fetchurl}: stdenv.mkDerivation {
  name = "expat-2.0.0";
  src = fetchurl {
    url = mirror://sourceforge/expat/expat-2.0.0.tar.gz;
    md5 = "d945df7f1c0868c5c73cf66ba9596f3f";
  };
}
