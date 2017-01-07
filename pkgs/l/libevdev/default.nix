{ stdenv
, fetchurl

, python
}:

stdenv.mkDerivation rec {
  name = "libevdev-1.5.6";

  src = fetchurl {
    url = "https://www.freedesktop.org/software/libevdev/${name}.tar.xz";
    hashOutput = false;
    multihash = "QmRc3DCwUrSvRvtLNLMmwMYFtnCJ5M5WDhoCBphLpBpjAe";
    sha256 = "ecec7e9d66b1d3692f10b3b20aa97fb25e874a784c5552a7b1698091fef5a688";
  };

  buildInputs = [
    python
  ];

  configureFlags = [
    "--disable-silent"
  ];

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.sig") src.urls;
      pgpKeyFingerprint = "3C2C 43D9 447D 5938 EF45  51EB E23B 7E70 B467 F0BF";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    description = "Wrapper library for evdev devices";
    homepage = http://www.freedesktop.org/software/libevdev/doc/latest/index.html;
    license = licenses.mit;
    maintainers = with stdenv.lib; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
