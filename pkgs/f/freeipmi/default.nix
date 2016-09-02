{ stdenv
, fetchurl

, libgcrypt
}:

stdenv.mkDerivation rec {
  name = "freeipmi-1.5.3";

  src = fetchurl {
    url = "mirror://gnu/freeipmi/${name}.tar.gz";
    hashOutput = false;
    sha256 = "5d36225b01cc965812e234e708d640381d030edf7689d4264d6f64c26a3c9868";
  };

  buildInputs = [
    libgcrypt
  ];
  
  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
  ];

  preInstall = ''
    installFlagsArray+=(
      "sysconfdir=$out/etc"
      "FREEIPMI_SYSCONFDIR=$out/etc/freeipmi"
      "FREEIPMI_CONFIG_FILE_DEFAULT=$out/etc/freeipmi/freeipmi.conf"
      "INTERPRET_SEL_CONFIG_FILE_DEFAULT=$out/etc/freeipmi/freeipmi_interpret_sel.conf"
      "INTERPRET_SENSOR_CONFIG_FILE_DEFAULT=$out/etc/freeipmi/freeipmi_interpret_sensor.conf"
      "IPMIDETECTD_CONFIG_FILE_DEFAULT=$out/etc/freeipmi/ipmidetectd.conf"
      "IPMIDETECT_CONFIG_FILE_DEFAULT=$out/etc/freeipmi/ipmidetect.conf"
      "IPMISELD_CONFIG_FILE_DEFAULT=$out/etc/freeipmi/ipmiseld.conf"
      "LIBIPMICONSOLE_CONFIG_FILE_DEFAULT=$out/etc/freeipmi/libipmiconsole.conf"
      "IPMISELD_CACHE_DIRECTORY=$TMPDIR"
      "IPMI_MONITORING_SDR_CACHE_DIR=$TMPDIR"
      "localstatedir=$TMPDIR"
    )
  '';

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.sig") src.urls;
      pgpKeyFingerprint = "A865 A9FB 6F03 8762 4468  543A 3EFB 7C4B E830 3927";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
