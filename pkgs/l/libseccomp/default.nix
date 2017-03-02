{ stdenv
, fetchurl

, getopt
}:

let
  version = "2.3.2";
in
stdenv.mkDerivation rec {
  name = "libseccomp-${version}";

  src = fetchurl {
    url = "https://github.com/seccomp/libseccomp/releases/download/v${version}/${name}.tar.gz";
    hashOutput = false;
    sha256 = "3ddc8c037956c0a5ac19664ece4194743f59e1ccd4adde848f4f0dae7f77bca1";
  };

  buildInputs = [
    getopt
  ];

  patchPhase = ''
    patchShebangs .
  '';

  passthru = {
    srcVerification = fetchurl rec {
      failEarly = true;
      sha256Urls = map (n: "${n}.SHA256SUM.asc") src.urls;
      pgpKeyFingerprint = "7100 AADF AE6E 6E94 0D2E  0AD6 55E4 5A5A E8CA 7C8A";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    description = "high level library for the Linux Kernel seccomp filter";
    homepage = "http://sourceforge.net/projects/libseccomp";
    license = licenses.lgpl2;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
