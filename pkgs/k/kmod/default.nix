{ stdenv
, fetchurl
, libxslt

, xz
, zlib
}:

let
  name = "kmod-24";

  tarballUrls = [
    "mirror://kernel/linux/utils/kernel/kmod/${name}.tar"
  ];
in
stdenv.mkDerivation rec {
  inherit name;

  src = fetchurl {
    urls = map (n: "${n}.xz") tarballUrls;
    hashOutput = false;
    sha256 = "610b8d1df172acc39a4fdf1eaa47a57b04873c82f32152e7a62e29b6ff9cb397";
  };

  nativeBuildInputs = [
    libxslt
  ];

  buildInputs = [
    xz
    zlib
  ];

  patches = [
    ./module-dir.patch
  ];

  configureFlags = [
    "--sysconfdir=/etc"
    "--with-xz"
    "--with-zlib"
  ];

  # Use symlinks instead of hard-links or copies
  postInstall = ''
    ln -s kmod $out/bin/lsmod
    mkdir -p $out/sbin
    for prog in rmmod insmod modinfo modprobe depmod; do
      ln -sv $out/bin/kmod $out/sbin/$prog
    done
  '';

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      pgpsigUrl = map (n: "${n}.sign") tarballUrls;
      pgpDecompress = true;
      pgpKeyFingerprint = "EAB3 3C96 9001 3C73 3916  AC83 9BA2 A5A6 30CB EA53";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    homepage = http://www.kernel.org/pub/linux/utils/kernel/kmod/;
    description = "Tools for loading and managing Linux kernel modules";
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
