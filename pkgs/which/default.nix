{ stdenv
, fetchurl
}:

stdenv.mkDerivation rec {
  name = "which-2.21";
  
  src = fetchurl {
    url = "mirror://gnu/which/${name}.tar.gz";
    sha256 = "1bgafvy3ypbhhfznwjv1lxmd6mci3x1byilnnkc7gcr486wlb8pl";
  };

  meta = with stdenv.lib; {
    homepage = http://ftp.gnu.org/gnu/which/;
    license = licenses.gpl3;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}
