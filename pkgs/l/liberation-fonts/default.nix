{ stdenv
, fetchurl

, fontforge
, pythonPackages
}:

let
  version = "2.00.1";
in
stdenv.mkDerivation rec {
  name = "liberation-fonts-${version}";

  src = fetchurl {
    url = "https://fedorahosted.org/releases/l/i/liberation-fonts/"
      + "${name}.tar.gz";
    sha256 = "1ymryvd2nw4jmw4w5y1i3ll2dn48rpkqzlsgv7994lk6qc9cdjvs";
  };

  buildInputs = [
    fontforge
    pythonPackages.fonttools
    pythonPackages.python
  ];

  preBuild = ''
    makeFlagsArray+=("FONT_S=$sourceRoot/liberation-fonts-ttf-${version}")
  '';

  installPhase = ''
    local Font
    for Font in $(find . -name '*.ttf') ; do
      install -D -m644 -v "$Font" \
        "$out/share/fonts/truetype/$(basename "$Font")"
    done
  '';

  meta = with stdenv.lib; {
    description = "Liberation Fonts";
    homepage = https://fedorahosted.org/liberation-fonts/;
    license = licenses.ofl;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}
