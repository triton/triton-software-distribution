{ stdenv
, fetchurl
, pythonPackages

, glib
, gmime
, talloc
, xapian-core
, zlib
}:

stdenv.mkDerivation rec {
  name = "notmuch-0.24.2";

  src = fetchurl {
    url = "https://notmuchmail.org/releases/${name}.tar.gz";
    multihash = "Qmb2U5zST4nkC1U2RZr5SdetNAqdA2aNGfGBzRaVKSMBaU";
    hashOutput = false;
    sha256 = "aa76a96684d5c5918d940182b6fe40f7d6745f144476fdda57388479d586cc51";
  };

  nativeBuildInputs = [
    pythonPackages.python
    pythonPackages.sphinx
  ];

  buildInputs = [
    glib
    gmime
    talloc
    xapian-core
    zlib
  ];

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      sha256Urls = map (n: "${n}.sha256.asc") src.urls;
      pgpKeyFingerprint = "815B 6398 2A79 F8E7 C727  86C4 762B 57BB 7842 06AD";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
