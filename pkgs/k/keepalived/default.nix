{ stdenv
, fetchurl

, file
, glib
, ipset
, iptables
, json-c
, libnfnetlink
, libnl
, net-snmp
, openssl
, pcre2_lib
}:

let
  version = "2.0.20";
in
stdenv.mkDerivation rec {
  name = "keepalived-${version}";

  src = fetchurl {
    url = "http://keepalived.org/software/${name}.tar.gz";
    multihash = "QmZQBKsTvWZ2ApEBvZWiuJyDuWVJd4RCDxfRam3oEzLbdT";
    hashOutput = false;
    sha256 = "9670fbc5eb3dc113828be8b702549dc68ec9578cf83287520d935be76fc8f193";
  };

  buildInputs = [
    file
    glib
    ipset
    iptables
    json-c
    libnfnetlink
    libnl
    net-snmp
    openssl
    pcre2_lib
  ];

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    "--disable-silent-rules"
    "--enable-bfd"
    "--enable-snmp"
    "--enable-snmp-vrrp"
    "--enable-snmp-checker"
    "--enable-snmp-rfc"
    "--enable-snmp-rfcv2"
    "--enable-snmp-rfcv3"
    "--enable-dbus"
    "--enable-regex"
    "--enable-regex-timers"
    "--enable-json"
    "--enable-sha1"
    "--enable-dynamic-linking"
    "--enable-netlink-timers"
    "--with-init=systemd"
  ];

  preConfigure = ''
    configureFlagsArray+=("--with-systemdsystemunitdir=$out/lib/systemd/system")
  '';

  preInstall = ''
    installFlagsArray+=(
      "dbussystemdir=$out/etc/dbus-1"
      "sysconfdir=$out/etc"
    )
  '';

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      inherit (src)
        urls
        outputHash
        outputHashAlgo;
      fullOpts = {
        md5Confirm = "a5966e8433b60998709c4a922a407bac";
      };
    };
  };

  meta = with stdenv.lib; {
    homepage = http://keepalived.org;
    description = "routing software written in C";
    license = licenses.gpl2;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
