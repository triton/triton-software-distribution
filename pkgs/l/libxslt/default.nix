{ stdenv
, fetchurl

, findXMLCatalogs
, libxml2
}:

let
  tarballUrls = version: [
    "http://xmlsoft.org/sources/libxslt-${version}.tar.gz"
  ];

  version = "1.1.29";
in
stdenv.mkDerivation rec {
  name = "libxslt-${version}";

  src = fetchurl {
    urls = tarballUrls version;
    hashOutput = false;
    sha256 = "b5976e3857837e7617b29f2249ebb5eeac34e249208d31f1fbf7a6ba7a4090ce";
  };

  buildInputs = [
    libxml2
  ];

  propagatedBuildInputs = [
    findXMLCatalogs
  ];

  configureFlags = [
    "--with-libxml-prefix=${libxml2}"
    "--without-python"
    "--with-crypto"
    "--without-debug"
    "--without-mem-debug"
    "--without-debugger"
  ];

  passthru = {
    srcVerification = fetchurl rec {
      failEarly = true;
      urls = tarballUrls "1.1.29";
      pgpsigUrls = map (n: "${n}.asc") urls;
      pgpKeyFingerprint = "C744 15BA 7C9C 7F78 F02E  1DC3 4606 B8A5 DE95 BC1F";
      inherit (src) outputHashAlgo;
      outputHash = "b5976e3857837e7617b29f2249ebb5eeac34e249208d31f1fbf7a6ba7a4090ce";
    };
  };

  meta = with stdenv.lib; {
    homepage = http://xmlsoft.org/XSLT/;
    description = "A C library and tools to do XSL transformations";
    license = licenses.bsd3;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
