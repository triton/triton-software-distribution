{ stdenv
, bison
, fetchurl
, flex
}:

let
  version = "1.4.5";

  tarballUrls = [
    "mirror://kernel/software/utils/dtc/dtc-${version}.tar"
  ];
in
stdenv.mkDerivation rec {
  name = "dtc-${version}";

  src = fetchurl {
    urls = map (n: "${n}.xz") tarballUrls;
    hashOutput = false;
    sha256 = "042c7164806af34069d13ede59d85b8156d09f179f721c516dc37712d3a0f621";
  };

  nativeBuildInputs = [
    flex
    bison
  ];

  makeFlags = [
    "NO_PYTHON=yes"
  ];

  preInstall = ''
    installFlagsArray+=(
      "INSTALL=install"
      "PREFIX=$out"
    )
  '';

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.sign") tarballUrls;
      pgpDecompress = true;
      pgpKeyFingerprint = "75F4 6586 AE61 A66C C44E  87DC 6C38 CACA 20D9 B392";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    description = "Device Tree Compiler";
    homepage = https://git.kernel.org/cgit/utils/dtc/dtc.git;
    license = licenses.gpl2; # dtc itself is GPLv2, libfdt is dual GPL/BSD
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
