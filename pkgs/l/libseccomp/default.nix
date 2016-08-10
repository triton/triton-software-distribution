{ stdenv
, fetchurl

, getopt
}:

let
  version = "2.3.0";
in
stdenv.mkDerivation rec {
  name = "libseccomp-${version}";

  src = fetchurl {
    url = "https://github.com/seccomp/libseccomp/releases/download/v${version}/${name}.tar.gz";
    allowHashOutput = false;
    sha256 = "d756e3a77578259a808698a50c43d44612aae3339ea42ab5b15ea983f26b901d";
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
