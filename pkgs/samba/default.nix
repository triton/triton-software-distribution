{ stdenv
, docbook_xml_dtd_42
, docbook_xml_dtd_45
, docbook_xsl
, fetchurl
, gettext
, libxslt
, perl
, pythonPackages

, avahi
, acl
, ceph_lib
, cups
, dbus
, glusterfs
, gnutls
, iniparser
, kerberos
, ldb
, libaio
, libarchive
, libbsd
, libcap
, libgcrypt
, libgpg-error
, libibverbs
, librdmacm
, libunwind
, ncurses
, nss_wrapper
, openldap
, pam
, popt
, readline
, resolv_wrapper
, socket_wrapper
, subunit
, systemd_lib
, talloc
, tdb
, tevent
, uid_wrapper
, zlib

, type ? ""
}:

let
  inherit (stdenv.lib)
    optionals
    optionalString;

  version = "4.4.4";
  name = "samba${if isClient then "-client" else ""}-${version}";

  tarballUrls = [
    "mirror://samba/samba/stable/samba-${version}.tar"
  ];

  isClient = type == "client";
in
stdenv.mkDerivation rec {
  inherit name;

  src = fetchurl {
    urls = map (n: "${n}.gz") tarballUrls;
    allowHashOutput = false;
    sha256 = "262f9edabbd1c0112819b5063718588c22b0ee4c1a2f648f79f233fdfba25c8b";
  };

  nativeBuildInputs = [
    pythonPackages.python
    perl
    libxslt
    docbook_xsl
    docbook_xml_dtd_42
    docbook_xml_dtd_45
    pythonPackages.wrapPython
    gettext
  ];

  buildInputs = [
    acl
    avahi
    cups
    gnutls
    iniparser
    kerberos
    ldb
    libarchive
    libbsd
    libcap
    libgcrypt
    libgpg-error
    libunwind
    ncurses
    nss_wrapper
    openldap
    pam
    popt
    readline
    resolv_wrapper
    socket_wrapper
    subunit
    systemd_lib
    talloc
    tdb
    tevent
    uid_wrapper
    zlib
  ] ++ optionals (!isClient) [
    ceph_lib
    dbus
    glusterfs
    libaio
    libibverbs
    librdmacm
  ];

  pythonPath = [
    talloc
    ldb
    tdb
  ];

  postPatch = ''
    # Removes absolute paths in scripts
    sed -i 's,/sbin/,,g' ctdb/config/functions

    # Fix the XML Catalog Paths
    sed -i "s,\(XML_CATALOG_FILES=\"\),\1$XML_CATALOG_FILES ,g" buildtools/wafsamba/wafsamba.py
  '';

  configureFlags = [
    # source3/wscript options
    "--with-static-modules=NONE"
    "--with-shared-modules=ALL"
    "--with-winbind"
    "--with-ads"
    "--with-ldap"
    "--enable-cups"
    "--enable-iprint"
    "--with-pam"
    "--with-quotas"
    "--with-sendfile-support"
    "--with-utmp"
    "--with-utmp"
    "--enable-pthreadpool"
    "--enable-avahi"
    "--with-iconv"
    "--with-acl-support"
    "--with-dnsupdate"
    "--with-syslog"
    "--with-automount"
    "--without-fam"
    "--with-libarchive"
    "--with-cluster-support"
    "--with-regedit"
    (if isClient then null else "--with-libcephfs=${ceph_lib}")
    (if isClient then null else "--enable-glusterfs")

    # dynconfig/wscript options
    "--enable-fhs"
    "--sysconfdir=/etc"
    "--localstatedir=/var"

    # buildtools/wafsamba/wscript options
    "--bundled-libraries=com_err"
    "--private-libraries=NONE"
    "--builtin-libraries=replace"
    "--abi-check"
    "--why-needed"
    "--with-libiconv"

    # lib/util/wscript
    "--with-systemd"

    # source4/lib/tls/wscript options
    "--enable-gnutls"

    # wscript options
    "--with-system-mitkrb5"
    # "--without-ad-dc"

    # ctdb/wscript
    (if isClient then null else "--enable-infiniband")
    (if isClient then null else "--enable-pmda")
  ];

  preInstall = ''
    sed \
      -e "s,'/etc,'$out/etc,g" \
      -e "s,'/var,'$TMPDIR/var,g" \
      -i bin/c4che/default.cache.py
  '';

  postInstall = ''
    # Remove unecessary components
    rm -r $out/{lib,share}/ctdb-tests
    rm $out/bin/ctdb_run{_cluster,}_tests
  '';

  preFixup = optionalString isClient ''
    smbclient_bins=(
      "$out/bin/smbclient"
      "$out/bin/rpcclient"
      "$out/bin/smbspool"
      "$out/bin/smbtree"
      "$out/bin/smbcacls"
      "$out/bin/smbcquotas"
      "$out/bin/smbget"
      "$out/bin/net"
      "$out/bin/nmblookup"
      "$out/bin/smbtar"
    )
    for lib in $(find $out/lib $out/lib/security -maxdepth 1 -not -type d); do
      smbclient_bins+=("$lib")
    done

    smbclient_pcs=($(find "$out/lib/pkgconfig" -type f))
    for smbclient_pc in "''${smbclient_pcs[@]}"; do
      names=$(sed 's, -l,\n\0,g' $smbclient_pc | sed -n 's,.* -l\([^ ]*\).*,\1,p')
      for name in $names; do
        smbclient_bins+=($(find $out/lib -name lib''${name}.so\*))
      done
    done

    for smbclient_bin in "''${smbclient_bins[@]}"; do
      smbclient_bins+=($(ldd $smbclient_bin | awk '{ print $3 }' | grep $out || true))
    done

    declare -A smbclient_files
    for i in "''${smbclient_bins[@]}" "''${smbclient_pcs[@]}" $(find $out/include $out/lib/python* -not -type d); do
      smbclient_files["$i"]=1
    done

    for i in $(find $out -not -type d); do
      if [ "''${smbclient_files[$i]}" != "1" ]; then
        rm $i
      fi
    done
    for dir in $(find $out -type d | sort -r); do
      rmdir "$dir" || true
    done
  '' + ''
    # Correct python program paths
    wrapPythonPrograms $out/bin
  '';

  # We need to make sure rpaths are correct for all of our libraries
  postFixup = ''
    SAMBA_LIBS="$(find $out -type f -name \*.so -exec dirname {} \; | sort | uniq)"
    while read BIN; do
      OLD_LIBS="$(patchelf --print-rpath "$BIN" 2>/dev/null | tr ':' '\n')" || continue
      ALL_LIBS="$(echo -e "$SAMBA_LIBS\n$OLD_LIBS" | sort | uniq | tr '\n' ':')"
      patchelf --set-rpath "$ALL_LIBS" "$BIN" 2>/dev/null
      patchelf --shrink-rpath "$BIN"
    done < <(find $out -type f)
  '';

  passthru = rec {
    srcVerified = fetchurl {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.asc") tarballUrls;
      pgpDecompress = true;
      inherit (pgp.samba) pgpKeyFingerprint;
      inherit (src) urls outputHash outputHashAlgo;
    };

    pgp = {
      samba = {
        pgpKeyFingerprint = "52FB C0B8 6D95 4B08 4332  4CDC 6F33 915B 6568 B7EA";
      };
      library = {
        pgpKeyFingerprint = "9147 A339 7195 18EE 9011  BCB5 4793 9161 1308 4025";
      };
    };
  };

  meta = with stdenv.lib; {
    homepage = http://www.samba.org/;
    description = "The standard Windows interoperability suite of programs for Linux and Unix";
    license = licenses.gpl3;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
