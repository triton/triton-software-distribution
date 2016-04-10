{ stdenv
, fetchFromGitHub

, ncurses
}:

stdenv.mkDerivation rec {
  name = "sl-${version}";
  version = "5.02";

  src = fetchFromGitHub {
    owner = "mtoyoda";
    repo = "sl";
    rev = version;
    sha256 = "d52d3b025e9aa5d728dc459f8d945cb979f6f9b82a43254693f6b413ec94fc3e";
  };

  buildInputs = [
    ncurses
  ];

  installPhase = ''
    mkdir -p $out/bin $out/share/man/man1
    cp sl $out/bin
    cp sl.1 $out/share/man/man1
  '';

  meta = with stdenv.lib; {
    homepage = http://www.tkl.iis.u-tokyo.ac.jp/~toyoda/index_e.html;
    description = "Steam Locomotive runs across your terminal when you type 'sl'";
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
