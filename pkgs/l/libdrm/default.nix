{ stdenv
, fetchurl

, xorg
}:

stdenv.mkDerivation rec {
  name = "libdrm-2.4.71";

  src = fetchurl {
    url = "https://dri.freedesktop.org/libdrm/${name}.tar.bz2";
    hashOutput = false;
    multihash = "QmWZznUmnCeyirF3Wk1MhG1mKDExh59ds9shZnLSVJYam2";
    sha256 = "c66287ddeee5f46ea8f8880b94b80acb3bbc33ba6321d17767eef145046df9b8";
  };

  buildInputs = [
    xorg.libpthreadstubs
    xorg.libpciaccess
  ];

  configureFlags = [
    "--enable-largefile"
    # Udev is only used by tests now.
    "--disable-udev"
    "--enable-libkms"
    "--enable-intel"
    "--enable-radeon"
    "--enable-amdgpu"
    "--enable-nouveau"
    "--enable-omap-experimental-api"
    "--enable-exynos-experimental-api"
    "--enable-freedreno"
    "--disable-freedreno-kgsl"
    "--enable-tegra-experimental-api"
    "--disable-install-test-programs"
    "--disable-cairo-tests"
    "--disable-manpages"
    "--disable-valgrind"
    #"--with-xsltproc"
    #"--with-kernel-source"
  ];

  # This breaks libraries talking to the dri interfaces
  bindnow = false;

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.sig") src.urls;
      pgpKeyFingerprints = [
        "E8EB 5B34 081C E1EE A26E  FE19 5B5B DA07 1D49 CC38"
        "FC9B AE14 35A9 F7F6 64B8  2057 B5D6 2936 D1FC 9EE8"
        "D628 5B5E 8992 99F3 DA74  6184 191C 9B90 5522 B045"
      ];
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    description = "Library for accessing the kernel's Direct Rendering Manager";
    homepage = http://dri.freedesktop.org/libdrm/;
    license = licenses.bsd3;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
