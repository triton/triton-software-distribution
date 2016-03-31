{ stdenv
, cmake
, fetchFromGitHub
, ninja
}:

stdenv.mkDerivation rec {
  name = "pugixml-${version}";
  version = "1.7";

  src = fetchFromGitHub {
    owner = "zeux";
    repo = "pugixml";
    rev = "v${version}";
    sha256 = "b4dc913f28763da0ce56cf091500f9ac728b83ba50a269cff9f2c91378e27e08";
  };

  nativeBuildInputs = [
    cmake
    ninja
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
  ];

  preConfigure = ''
    # Enable long long support (required for filezilla)
    #sed -ire '/PUGIXML_HAS_LONG_LONG/ s/^\/\///' src/pugiconfig.hpp
    cd scripts
  '';

  meta = with stdenv.lib; {
    description = "Light-weight, simple and fast XML parser for C++ with XPath support";
    homepage = http://pugixml.org/;
    license = licenses.mit;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
