{ stdenv, fetchurl, pythonPackages, pkgconfig, perl, libxslt, docbook_xsl
, docbook_xml_dtd_42, docbook_xml_dtd_45, readline, talloc, tdb, tevent
, ldb, popt, iniparser, subunit, libbsd, nss_wrapper, resolv_wrapper
, socket_wrapper, uid_wrapper, libarchive

# source3/wscript optionals
, kerberos ? null
, zlib ? null
, openldap ? null
, cups ? null
, pam ? null
, avahi ? null
, acl ? null
, libaio ? null
, fam ? null
, libceph ? null
, glusterfs ? null

# buildtools/wafsamba/wscript optionals
, libiconv ? null
, gettext ? null

# source4/lib/tls/wscript optionals
, gnutls ? null
, libgcrypt ? null
, libgpgerror ? null

# other optionals
, ncurses ? null
, libunwind ? null
, dbus ? null
, libibverbs ? null
, librdmacm ? null
, systemd ? null
}:

assert kerberos != null -> zlib != null;

let
  bundledLibs = if kerberos != null && kerberos.implementation == "heimdal" then "NONE" else "com_err";
  hasGnutls = gnutls != null && libgcrypt != null && libgpgerror != null;
  isKrb5OrNull = if kerberos != null && kerberos.implementation == "krb5" then true else null;
  #hasInfinibandOrNull = if libibverbs != null && librdmacm != null then true else null;
  hasInfinibandOrNull = null;  # TODO(wkennington): Reenable after fixed
in
with stdenv.lib;
stdenv.mkDerivation rec {
  name = "samba-4.3.4";

  src = fetchurl {
    url = "mirror://samba/pub/samba/stable/${name}.tar.gz";
    sha256 = "1n8r2i7s53714xkxyfzc0qlij8zzmip72mvx5y9ayci8hhpba3jx";
  };

  patches = [
    ./4.x-no-persistent-install.patch
    ./4.x-fix-ctdb-deps.patch
  ] ++ optional (kerberos != null) ./4.x-heimdal-compat.patch;

  nativeBuildInputs = [
    pythonPackages.python pkgconfig perl libxslt docbook_xsl docbook_xml_dtd_42
    pythonPackages.wrapPython
  ];
  buildInputs = [
    readline talloc tdb tevent ldb popt iniparser
    subunit libbsd nss_wrapper resolv_wrapper socket_wrapper uid_wrapper
    libarchive

    kerberos zlib openldap cups pam avahi acl libaio fam libceph glusterfs

    libiconv gettext

    gnutls libgcrypt libgpgerror

    ncurses libunwind dbus libibverbs librdmacm systemd
  ];

  pythonPath = [ talloc ldb tdb ];

  postPatch = ''
    # Removes absolute paths in scripts
    sed -i 's,/sbin/,,g' ctdb/config/functions

    # Fix the XML Catalog Paths
    sed -i "s,\(XML_CATALOG_FILES=\"\),\1$XML_CATALOG_FILES ,g" buildtools/wafsamba/wafsamba.py
  '';

  enableParallelBuilding = true;

  configureFlags = [
    # source3/wscript options
    (mkWith   true                 "static-modules"    "NONE")
    (mkWith   true                 "shared-modules"    "ALL")
    (mkWith   true                 "winbind"           null)
    (mkWith   (openldap != null)   "ads"               null)
    (mkWith   (openldap != null)   "ldap"              null)
    (mkEnable (cups != null)       "cups"              null)
    (mkEnable (cups != null)       "iprint"            null)
    (mkWith   (pam != null)        "pam"               null)
    (mkWith   (pam != null)        "pam_smbpass"       null)
    (mkWith   true                 "quotas"            null)
    (mkWith   true                 "sendfile-support"  null)
    (mkWith   true                 "utmp"              null)
    (mkWith   true                 "utmp"              null)
    (mkEnable true                 "pthreadpool"       null)
    (mkEnable (avahi != null)      "avahi"             null)
    (mkWith   true                 "iconv"             null)
    (mkWith   (acl != null)        "acl-support"       null)
    (mkWith   true                 "dnsupdate"         null)
    (mkWith   true                 "syslog"            null)
    (mkWith   true                 "automount"         null)
    (mkWith   (libaio != null)     "aio-support"       null)
    (mkWith   (fam != null)        "fam"               null)
    (mkWith   (libarchive != null) "libarchive"        null)
    (mkWith   true                 "cluster-support"   null)
    (mkWith   (ncurses != null)    "regedit"           null)
    (mkWith   libceph              "libcephfs"         libceph)
    (mkEnable (glusterfs != null)  "glusterfs"         null)

    # dynconfig/wscript options
    (mkEnable true                 "fhs"               null)
    (mkOther                       "sysconfdir"        "/etc")
    (mkOther                       "localstatedir"     "/var")

    # buildtools/wafsamba/wscript options
    (mkOther                       "bundled-libraries" bundledLibs)
    (mkOther                       "private-libraries" "NONE")
    (mkOther                       "builtin-libraries" "replace")
    (mkWith   libiconv             "libiconv"          libiconv)
    (mkWith   (gettext != null)    "gettext"           gettext)

    # lib/util/wscript
    (mkWith   (systemd != null)    "systemd"           null)

    # source4/lib/tls/wscript options
    (mkEnable hasGnutls            "gnutls" null)

    # wscript options
    (mkWith   isKrb5OrNull         "system-mitkrb5"    null)
    (if hasGnutls then null else "--without-ad-dc")

    # ctdb/wscript
    (mkEnable hasInfinibandOrNull  "infiniband"        null)
    (mkEnable null                 "pmda"              null)
  ];

  stripAllList = [ "bin" "sbin" ];

  postInstall = ''
    # Remove unecessary components
    rm -r $out/{lib,share}/ctdb-tests
    rm $out/bin/ctdb_run{_cluster,}_tests

    # Correct python program paths
    wrapPythonPrograms
  '';

  preFixup = ''
    # Fix broken pc file generation
    sed -i $out/lib/pkgconfig/ctdb.pc \
      -e "s,@libdir@,$out/lib,g" \
      -e "s,@includedir@,$out/include,g"
  '';

  postFixup = ''
    SAMBA_LIBS="$(find $out -type f -name \*.so -exec dirname {} \; | sort | uniq)"
    find $out -type f | while read BIN; do
      OLD_LIBS="$(patchelf --print-rpath "$BIN" 2>/dev/null | tr ':' '\n')" || continue
      ALL_LIBS="$(echo -e "$SAMBA_LIBS\n$OLD_LIBS" | sort | uniq | tr '\n' ':')"
      patchelf --set-rpath "$ALL_LIBS" "$BIN" 2>/dev/null
      patchelf --shrink-rpath "$BIN"
    done
  '';

  meta = {
    homepage = http://www.samba.org/;
    description = "The standard Windows interoperability suite of programs for Linux and Unix";
    license = licenses.gpl3;
    maintainers = with maintainers; [ wkennington ];
    platforms = platforms.all;
  };
}
