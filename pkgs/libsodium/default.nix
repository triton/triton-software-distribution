{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name = "libsodium-1.0.8";

  src = fetchurl {
    urls = [
      "https://download.libsodium.org/libsodium/releases/${name}.tar.gz"
      "mirror://gentoo/distfiles/${name}.tar.gz"
    ];
    sha256 = "09hr604k9gdss2r321x5dv3wn11fdl87nswr18g68lkqab993wf0";
  };

  doCheck = true;

  meta = with stdenv.lib; {
    description = "A modern and easy-to-use crypto library";
    homepage = http://doc.libsodium.org/;
    license = licenses.isc;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}
