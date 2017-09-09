{ stdenv
, lib
, fetchurl

, ncurses
}:

stdenv.mkDerivation rec {
  name = "ncdu-1.12";

  src = fetchurl {
    url = "https://dev.yorhel.nl/download/${name}.tar.gz";
    multihash = "QmbDWb9ycS5sudqN1Q8JUAuui4T2MwyDiW8zJNCmD9YzNc";
    hashOutput = false;
    sha256 = "820e4e4747a2a2ec7a2e9f06d2f5a353516362c22496a10a9834f871b877499a";
  };
  
  buildInputs = [
    ncurses
  ];

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.asc") src.urls;
      pgpKeyFingerprint = "7446 0D32 B808 10EB A9AF  A2E9 6239 4C69 8C27 39FA";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with lib; {
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
