{ stdenv
, fetchurl

, xz
}:

stdenv.mkDerivation rec {
  name = "libunwind-1.2";

  src = fetchurl {
    url = "mirror://savannah/libunwind/${name}.tar.gz";
    hashOutput = false;
    sha256 = "1de38ffbdc88bd694d10081865871cd2bfbb02ad8ef9e1606aee18d65532b992";
  };

  buildInputs = [
    xz
  ];

  passthru = {
    srcVerification = fetchurl rec {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.sig") src.urls;
      pgpKeyFingerprints = [
        "5C96 BDEA F5F4 7FB0 2BD4  F6B9 65D9 8560 914F 3F48"
        "1675 C8DA 2EF9 07FB 116E  B709 EC52 B396 E687 4AF2"
      ];
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    homepage = http://www.nongnu.org/libunwind;
    description = "A portable and efficient API to determine the call-chain of a program";
    license = licenses.gpl2;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
