{ stdenv
, fetchurl

, bazaar
, python2
}:

let
  version = "2.6.0";
in
stdenv.mkDerivation rec {
  name = "bzrtools-${version}";

  src = fetchurl {
    url = "http://launchpad.net/bzrtools/stable/${version}/+download/${name}.tar.gz";
    sha256 = "0n3zzc6jf5866kfhmrnya1vdr2ja137a45qrzsz8vz6sc6xgn5wb";
  };

  buildInputs = [
    bazaar
    python2
  ];

  installPhase = ''
    ${python2.interpreter} ./setup.py install --prefix=$out
  '';

  meta = with stdenv.lib; {
    description = "BzrTools is a useful collection of utilities for bzr";
    homepage = http://wiki.bazaar.canonical.com/BzrTools;
    license = licenses.gpl2;
    maintainers = with maintainers; [ ];
    platforms = with platforms;
      x86_64-linux;
  };
}
