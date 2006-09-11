{ stdenv, fetchurl, apr, expat
, bdbSupport ? false, bdb ? null
}:

assert bdbSupport -> bdb != null;

stdenv.mkDerivation {
  name = "apr-util-1.2.7";
  src = fetchurl {
    url = http://archive.apache.org/dist/apr/apr-util-1.2.7.tar.bz2;
    md5 = "a4c527f08ae2298e62a88472291bf066";
  };
  configureFlags = "
    --with-apr=${apr} --with-expat=${expat}
    ${if bdbSupport then "--with-berkeley-db=${bdb}" else ""}
  ";
}
