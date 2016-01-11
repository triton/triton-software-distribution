{ stdenv, fetchurl, jdk, xorg, glib, gtk2, xulrunner, zip, pkgconfig, perl, npapi_sdk, bash, bc }:

stdenv.mkDerivation rec {
  name = "icedtea-web-${version}";

  version = "1.6.1";

  src = fetchurl {
    url = "http://icedtea.wildebeest.org/download/source/${name}.tar.gz";
    sha256 = "0869j9jn0z5b5pfspp4v5cj2ksmbqmmmjhqicn4kqc6wr6v6md59";
  };

  nativeBuildInputs = [ pkgconfig bc perl ];
  buildInputs = [ xorg.libX11 glib gtk2 xulrunner zip npapi_sdk ];

  preConfigure = ''
    #patchShebangs javac.in
    configureFlagsArray+=("BIN_BASH=${bash}/bin/bash")
  '';

  configureFlags = [
    "--with-jdk-home=${jdk.home}"
    "--disable-docs"
  ];

  mozillaPlugin = "/lib";

  meta = {
    description = "Java web browser plugin and an implementation of Java Web Start";
    longDescription = ''
      A Free Software web browser plugin running applets written in the Java
      programming language and an implementation of Java Web Start, originally
      based on the NetX project.
    '';
    homepage = http://icedtea.classpath.org/wiki/IcedTea-Web;
    maintainers = with stdenv.lib.maintainers; [ wizeman ];
    platforms = stdenv.lib.platforms.linux;
  };
}
