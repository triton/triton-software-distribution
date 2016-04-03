{ stdenv
, fetchurl
, makeWrapper
, perl

, coreutils
, gnused
, iproute
, iputils
, net-tools
, openldap
}:

stdenv.mkDerivation rec {
  name = "dhcp-${version}";
  version = "4.3.4";

  src = fetchurl {
    url = "http://ftp.isc.org/isc/dhcp/${version}/${name}.tar.gz";
    allowHashOutput = false;
    sha256 = "f5115aee3dd3e6925de4ba47b80ab732ba48b481c8364b6ebade2d43698d607e";
  };

  nativeBuildInputs = [
    perl
    makeWrapper
  ];

  buildInputs = [
    openldap
  ];

  postPatch = ''
    sed -i "includes/dhcpd.h" \
      -e "s|^ *#define \+_PATH_DHCLIENT_SCRIPT.*$|#define _PATH_DHCLIENT_SCRIPT \"$out/bin/dhclient-script\"|g"
  '';

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    "--disable-debug"
    "--enable-failover"
    "--enable-execute"
    "--enable-tracing"
    "--enable-delayed-ack"  # Experimental in 4.3.2
    "--enable-dhcpv6"
    "--enable-paranoia"
    "--enable-early-chroot"
    "--enable-ipv4-pktinfo"
    "--disable-use-sockets"
    "--disable-secs-byteorder"
    "--disable-log-pid"
    "--without-libbind"
    "--with-ldap"
    "--with-ldapcrypto"
  ];

  preInstall = ''
    installFlagsArray+=("sysconfdir=$out/etc")
  '';

  postInstall = ''
    cp client/scripts/linux $out/bin/dhclient-script
    substituteInPlace $out/bin/dhclient-script \
      --replace /sbin/ip ${iproute}/bin/ip
    wrapProgram "$out/bin/dhclient-script" --prefix PATH : \
      "${net-tools}/bin:${iputils}/bin:${coreutils}/bin:${gnused}/bin"
  '';

  # Fails to build the bind library if run in parallel
  parallelBuild = false;

  passthru = {
    sourceTarball = fetchurl {
      pgpsigUrls = map (n: "${n}.sha512.asc") src.urls;
      pgpKeyFile = ./signing.key;
      inherit (src) urls outputHashAlgo outputHash;
    };
  };

  meta = with stdenv.lib; {
    description = "Dynamic Host Configuration Protocol (DHCP) tools";
    homepage = http://www.isc.org/products/DHCP/;
    license = licenses.isc;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
