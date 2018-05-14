{ stdenv
, fetchurl
}:

let
  version = "0.12.2";
in
stdenv.mkDerivation rec {
  name = "libfilezilla-${version}";

  src = fetchurl {
    url = "mirror://filezilla/libfilezilla/${name}.tar.bz2";
    sha256 = "778c166fde3a87e04a0524a4bf92c3eea1f0836c20119dd0859c9cd9380c86ec";
  };

  meta = with stdenv.lib; {
    homepage = "https://lib.filezilla-project.org/index.php";
    license = licenses.lpgl21;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
