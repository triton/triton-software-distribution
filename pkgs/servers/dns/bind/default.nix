{ stdenv, fetchurl, libtool, docbook5_xsl

# Optional Dependencies
, libseccomp ? null, python ? null, kerberos ? null, openssl ? null
, libxml2 ? null, json_c ? null, readline ? null, libcap ? null, idnkit ? null
, libiconv ? null

# Optional DLZ Modules
, postgresql ? null, libmysql ? null, db ? null, openldap ? null
}:

assert postgresql != null;
with stdenv;
let
  version = "9.10.2";

  optLibseccomp = shouldUsePkg libseccomp;
  optPython = shouldUsePkg python;
  optKerberos = shouldUsePkg kerberos;
  optOpenssl = shouldUsePkg openssl;
  optLibxml2 = shouldUsePkg libxml2;
  optJson_c = shouldUsePkg json_c;
  optReadline = shouldUsePkg readline;
  optLibcap = if !stdenv.isLinux then null else shouldUsePkg libcap;
  optIdnkit = shouldUsePkg idnkit;
  optLibiconv = shouldUsePkg libiconv;

  optPostgresql = shouldUsePkg postgresql;
  optLibmysql = shouldUsePkg libmysql;
  optDb = shouldUsePkg db;
  optOpenldap = shouldUsePkg openldap;
in
assert optPostgresql != null;
with stdenv.lib;
stdenv.mkDerivation rec {
  name = "bind-${version}";

  src = fetchurl {
    url = "http://ftp.isc.org/isc/bind9/${version}/${name}.tar.gz";
    sha256 = "163s8pvqj4lyryvfzkc6acbys7gw1by5dqwilggiwp54ia8bg6vg";
  };

  patchPhase = ''
    sed -i 's/^\t.*run/\t/' Makefile.in
  '';

  nativeBuildInputs = [ optPython libtool docbook5_xsl ];
  buildInputs = [
    optLibseccomp optPython optKerberos optOpenssl optLibxml2 optJson_c
    optReadline optLibcap optIdnkit optLibiconv optPostgresql optLibmysql
    optDb optOpenldap
  ];

  configureFlags = [
    (mkOther                          "localstatedir"       "/var")
    (mkOther                          "sysconfdir"          "/etc")
    (mkEnable (optLibseccomp != null) "seccomp"             null)
    (mkWith   (optPython != null)     "python"              "${optPython}/bin/python")
    (mkEnable true                    "kqueue"              null)
    (mkEnable true                    "epoll"               null)
    (mkEnable true                    "devpoll"             null)
    (mkWith   false                   "geoip"               null)  # TODO(wkennington): GeoDNS support
    (mkWith   (optKerberos != null)   "gssapi"              optKerberos)
    (mkWith   true                    "libtool"             null)
    (mkEnable (optOpenssl == null)    "native-pkcs11"       null)
    (mkWith   (optOpenssl != null)    "openssl"             optOpenssl)
    (mkWith   true                    "pkcs11"              null)
    (mkWith   true                    "ecdsa"               null)
    (mkWith   false                   "gost"                null)  # Insecure cipher
    (mkWith   true                    "aes"                 null)
    (mkEnable (optOpenssl != null)    "openssl-hash"        null)
    (mkEnable true                    "sit"                 null)
    (mkWith   true                    "sit-alg"             "aes")
    (mkWith   (optLibxml2 != null)    "libxml2"             optLibxml2)
    (mkWith   (optJson_c != null)     "libjson"             optJson_c)
    (mkEnable true                    "largefile"           null)
    (mkWith   false                   "purify"              null)
    (mkWith   false                   "gperftools-profiler" null)
    (mkEnable false                   "backtrace"           null)
    (mkEnable false                   "symtable"            null)
    (mkEnable true                    "ipv6"                null)
    (mkWith   false                   "kame"                null)
    (mkWith   (optReadline != null)   "readline"            null)
    (mkEnable (optKerberos == null)   "isc-spnego"          null)
    (mkEnable true                    "chroot"              null)
    (mkEnable (optLibcap != null)     "linux-caps"          null)
    (mkEnable true                    "atomic"              null)
    (mkEnable false                   "fixed-rrset"         null)
    (mkEnable true                    "rpz-nsip"            null)
    (mkEnable true                    "rpz-nsdname"         null)
    (mkEnable true                    "filter-aaaa"         null)
    (mkWith   true                    "docbook-xsl"         "${docbook5_xsl}/share/xsl/docbook")
    (mkWith   (optIdnkit != null)     "idn"                 optIdnkit)
    (mkWith   (optLibiconv != null)   "libiconv"            optLibiconv)
    (mkWith   false                   "atf"                 null)
    (mkWith   true                    "tuning"              "large")
    (mkWith   true                    "dlopen"              null)
    (mkWith   false                   "make-clean"          null)
    (mkEnable true                    "full-report"         null)
    (mkWith   (optPostgresql != null) "dlz-postgres"        optPostgresql)
    (mkWith   (optLibmysql != null)   "dlz-mysql"           optLibmysql)
    (mkWith   (optDb != null)         "dlz-bdb"             optDb)
    (mkWith   true                    "dlz-filesystem"      null)
    (mkWith   (optOpenldap != null)   "dlz-ldap"            optOpenldap)
    (mkWith   false                   "dlz-odbc"            null)
    (mkWith   true                    "dlz-stub"            null)
  ];

  installFlags = [
    "sysconfdir=\${out}/etc"
    "localstatedir=\${TMPDIR}"
  ];

  meta = {
    homepage = "http://www.isc.org/software/bind";
    description = "Domain name server";
    license = licenses.isc;
    maintainers = with maintainers; [ viric simons wkennington ];
    platforms = platforms.unix;
  };
}
