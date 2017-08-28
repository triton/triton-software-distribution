{ stdenv
, fetchurl
, lib

, libpthread-stubs
, xorg
}:

stdenv.mkDerivation rec {
  name = "libdrm-2.4.83";

  src = fetchurl {
    url = "https://dri.freedesktop.org/libdrm/${name}.tar.bz2";
    multihash = "QmSm6uyaHnt5ee2eegH8PXEnooquJVVkSQCxUSGNN7U5Pn";
    hashOutput = false;
    sha256 = "03a52669da60ead62548a35bc430aafb6c2d8dd21ec9dba3a90f96eff5fe36d6";
  };

  buildInputs = [
    libpthread-stubs
    xorg.libpciaccess
  ];

  configureFlags = [
    "--enable-largefile"
    "--disable-udev"  # Udev is only used by tests.
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
        # Emil Velikov
        "8703 B670 0E7E E06D 7A39  B8D6 EDAE 37B0 2CEB 490D"
        # Kenneth Graunke
        "E8EB 5B34 081C E1EE A26E  FE19 5B5B DA07 1D49 CC38"
        # Eric Anholt
        "FC9B AE14 35A9 F7F6 64B8  2057 B5D6 2936 D1FC 9EE8"
        # Rob Clark
        "D628 5B5E 8992 99F3 DA74  6184 191C 9B90 5522 B045"
        # Robert Bragg
        "C20F 5C44 90D7 D64B 4C9A  0999 8CD1 DF55 2975 297B"
        # David Airlie
        "10A6 D91D A1B0 5BD2 9F6D  EBAC 0C74 F359 79C4 86BE"
        # Marek Olšák
        "CD47 C534 1A37 5F33 BEF7  BAFA FDD1 5D5A CEF0 F2B1"
        # Lucas Stach
        "CFD0 E654 BCBE 5DD2 D030  D222 CFCC 297C 6D0A 120B"
        # Daniel Stone
        "A66D 805F 7C93 29B4 C5D8  2767 CCC4 F07F AC64 1EFF"
      ];
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with lib; {
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
