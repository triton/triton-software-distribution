{ stdenv
, fetchurl

, coreutils
, readline
, systemd_lib
, thin-provisioning-tools
, util-linux_full
, util-linux_lib
}:

let
  baseUrls = [
    "ftp://sources.redhat.com/pub/lvm2/releases"
  ];
in
stdenv.mkDerivation rec {
  name = "lvm2-${version}";
  version = "2.02.152";

  src = fetchurl {
    urls = map (n: "${n}/LVM2.${version}.tgz") baseUrls;
    allowHashOutput = false;
    sha512 = "44ebf79ee90f371835d9525db09e98e439ca5a6fcec4bfe4cb790df4c11e32e6dc4abea6a60e2f4f5a5e85c635354f10cc4d5ad04bbbf21653a357ca581defac";
  };

  buildInputs = [
    readline
    thin-provisioning-tools
    systemd_lib
    util-linux_lib
  ];

  configureFlags = [
    "--enable-udev_rules"
    "--enable-udev_sync"
    "--enable-pkgconfig"
    "--enable-applib"
    "--enable-cmdlib"
    "--enable-dmeventd"
  ];

  preConfigure = ''
    substituteInPlace scripts/lvmdump.sh \
      --replace /usr/bin/tr ${coreutils}/bin/tr
    substituteInPlace scripts/lvm2_activation_generator_systemd_red_hat.c \
      --replace /usr/sbin/lvm $out/sbin/lvm \
      --replace /usr/bin/udevadm ${systemd_lib}/bin/udevadm

    sed -i /DEFAULT_SYS_DIR/d Makefile.in
    sed -i /DEFAULT_PROFILE_DIR/d conf/Makefile.in
  '';

  # To prevent make install from failing.
  preInstall = ''
    installFlagsArray+=(
      "OWNER="
      "GROUP="
      "confdir=$out/etc"
    )
  '';

  # Install systemd stuff.
  installTargets = [
    "install"
    "install_systemd_generators"
    "install_systemd_units"
    "install_tmpfiles_configuration"
  ];

  postInstall = ''
    substituteInPlace $out/lib/udev/rules.d/13-dm-disk.rules \
      --replace $out/sbin/blkid ${util-linux_full}/bin/blkid

    # Systemd stuff
    mkdir -p $out/etc/systemd/system $out/lib/systemd/system-generators
    cp scripts/blk_availability_systemd_red_hat.service $out/etc/systemd/system
    cp scripts/lvm2_activation_generator_systemd_red_hat $out/lib/systemd/system-generators
  '';

  passthru = {
    srcVerified = fetchurl rec {
      failEarly = true;
      sha512Urls = map (n: "${n}/sha512.sum") baseUrls;
      pgpsigUrls = map (n: "${n}.asc") src.urls;
      pgpKeyFingerprint = "8843 7EF5 C077 BD11 3D3B  7224 2281 91C1 567E 2C17";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    homepage = http://sourceware.org/lvm2/;
    descriptions = "Tools to support Logical Volume Management (LVM) on Linux";
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
