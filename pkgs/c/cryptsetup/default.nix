{ stdenv
, fetchurl
, lib

, json-c
, libargon2
, lvm2
, openssl
, popt
, python
, util-linux_lib
}:

let
  channel = "2.0";
  version = "${channel}.3";

  baseUrl = "mirror://kernel/linux/utils/cryptsetup/v${channel}";
in
stdenv.mkDerivation rec {
  name = "cryptsetup-${version}";

  src = fetchurl {
    url = "${baseUrl}/${name}.tar.xz";
    hashOutput = false;
    sha256 = "4d6cca04c1f5ff4a68d045d190efb2623087eda0274ded92f92a4b6911e501d4";
  };

  buildInputs = [
    json-c
    libargon2
    lvm2
    openssl
    popt
    python
    util-linux_lib
  ];

  configureFlags = [
    "--enable-libargon2"
    "--enable-python"
    "--with-crypto_backend=openssl"
  ];

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      pgpsigUrl = "${baseUrl}/${name}.tar.sign";
      pgpDecompress = true;
      pgpKeyFingerprint = "2A29 1824 3FDE 4664 8D06  86F9 D9B0 577B D93E 98FC";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with lib; {
    description = "LUKS for dm-crypt";
    homepage = http://code.google.com/p/cryptsetup/;
    license = licenses.gpl2;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
