{ stdenv
, fetchurl

, coreutils
, readline
, systemd_lib
, util-linux_full
, util-linux_lib
}:

stdenv.mkDerivation rec {
  name = "lvm2-${version}";
  version = "2.02.146";

  src = fetchurl {
    url = "ftp://sources.redhat.com/pub/lvm2/releases/LVM2.${version}.tgz";
    sha256 = "0jnj0msjcg3r0mirnpiph558q6sm885a0rh2vibd95abil1jzb1r";
  };

  configureFlags = [
    "--enable-udev_rules"
    "--enable-udev_sync"
    "--enable-pkgconfig"
    "--enable-applib"
    "--enable-cmdlib"
    "--enable-dmeventd"
  ];

  buildInputs = [
    readline
    systemd_lib
    util-linux_lib
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
