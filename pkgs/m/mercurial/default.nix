{ stdenv
, buildPythonPackage
, fetchurl
, lib
}:

buildPythonPackage rec {
  name = "mercurial-4.6";

  src = fetchurl {
    url = "https://www.mercurial-scm.org/release/${name}.tar.gz";
    multihash = "Qmcdasi9AmzMTPKSoXoce4vKJcGEPj2gMA1k128vzPwAyd";
    hashOutput = false;
    sha256 = "56ae3b10201adae37ad97fbd759cf3cea4ebe64c57641c059978c7a706ee6b49";
  };

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.asc") src.urls;
      pgpKeyFingerprints = [
        "FAD6 1395 F642 FC2B 33C8  4B9A 2057 81AC 682A 2D72"
        "3A81 5516 3D0E 20A5 30FC  B786 47A6 7FFA A346 AACE"
        "2BCC E14F 5C67 25AA 2EA8  AEB7 B9C9 DC82 4AA5 BDD5"
      ];
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with lib; {
    description = "Scalable distributed SCM";
    homepage = https://www.mercurial-scm.org/;
    license = licenses.gpl2;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
