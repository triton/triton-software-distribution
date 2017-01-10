{ stdenv
, fetchurl

, curl
, cyrus-sasl
, gdk-pixbuf
, gpsd
, grpc
, hiredis
, i2c-tools
, iptables
, jdk
, libatasmart
, libcap
, libdbi
, libgcrypt
, libmnl
, libnotify
, liboping
, libpcap
, libxml2
, lm-sensors
, lua
, lvm2
, mysql_lib
, net-snmp
, openldap
, perl
, postgresql
, protobuf-c
, protobuf-cpp
, python2
, python3
, rrdtool
, systemd_lib
, xfsprogs_lib
, yajl

, type
}:

let
  inherit (stdenv.lib)
    optionals
    optionalString;

  isBase = type == "base";
  isPlugins = type == "plugins";

  version = "5.7.0";
in
assert isBase || isPlugins;
stdenv.mkDerivation rec {
  name = "collectd-${type}-${version}";

  src = fetchurl {
    urls = [
      "https://storage.googleapis.com/collectd-tarballs/collectd-${version}.tar.bz2"
      ("https://github.com/collectd/collectd/releases/download"
        + "/collectd-${version}/collectd-${version}.tar.bz2")
    ];
    hashOutput = false;  # Hashes at: https://collectd.org/download.shtml
    sha256 = "25a05fbdc6baad571554342bbac6141928bf95a47fc60ee3b32e46d0c89ef2b2";
  };

  buildInputs = [
    libcap
    libgcrypt
  ] ++ optionals isPlugins [
    curl
    cyrus-sasl
    gdk-pixbuf
    gpsd
    grpc
    hiredis
    i2c-tools
    iptables
    jdk
    libatasmart
    libdbi
    libmnl
    libnotify
    liboping
    libpcap
    libxml2
    lm-sensors
    lua
    lvm2
    mysql_lib
    net-snmp
    openldap
    perl
    postgresql
    protobuf-c
    protobuf-cpp
    python2
    python3
    rrdtool
    systemd_lib
    xfsprogs_lib
    yajl
  ];

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
  ];

  preInstall = ''
    installFlagsArray+=(
      "sysconfdir=$out/etc"
      "localstatedir=$TMPDIR"
    )
  '';

  postInstall = optionalString isBase ''
    rm -rf "$out/lib/collectd"
  '' + optionalString isPlugins ''
    rm -rf "$out"/{bin,etc,include,lib/pkgconfig,sbin,share}
    rm -rf "$out"/lib/lib*
  '';

  meta = with stdenv.lib; {
    description = "System statistics collection daemon";
    homepage = http://collectd.org/;
    license = licenses.gpl2;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
