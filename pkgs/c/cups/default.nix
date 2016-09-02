{ stdenv
, fetchurl

, acl
, attr
, avahi
, dbus
, gnutls
#, kerberos
, libgcrypt
, libpaper
, libusb
, pam
, python2
#, openjdk
, systemd_lib
, xdg-utils
#, xinetd
, zlib
}:

let
  inherit (stdenv.lib)
    enFlag
    wtFlag;

  version = "2.1.4";
in
stdenv.mkDerivation rec {
  name = "cups-${version}";

  src = fetchurl {
    url = "https://github.com/apple/cups/releases/download/release-${version}/"
      + "cups-${version}-source.tar.gz";
    hashOutput = false;
    sha256 = "4b14fd833180ac529ebebea766a09094c2568bf8426e219cb3a1715304ef728d";
  };

  buildInputs = [
    acl
    attr
    avahi
    dbus
    gnutls
    #kerberos
    libgcrypt
    libpaper
    libusb
    pam
    python2
    #openjdk
    systemd_lib
    xdg-utils
    #xinetd
    zlib
  ];

  preConfigure = ''
    configureFlagsArray+=(
      "--with-systemd=$out/lib/systemd/system"
      "--with-dbusdir=$out/etc/dbus-1"
      "--with-docdir=$out/share/cups/html"
      "--with-xinetd=$out/etc/xinetd.d"
    )
  '';

  configureFlags = [
    "--localstatedir=/var"
    "--sysconfdir=/etc"
    "--disable-mallinfo"
    (enFlag "libpaper" (libpaper != null) null)
    (enFlag "libusb" (libusb != null) null)
    #--enable-tcp-wrappers
    (enFlag "acl" (acl != null) null)
    (enFlag "dbus" (dbus != null) null)
    "--enable-shared"
    "--disable-libtool-unsupported"
    "--disable-debug"
    "--disable-debug-guards"
    "--disable-debug-printfs"
    "--disable-unit-tests"
    #"--enable-relro"
    #(enFlag "gssapi" (kerberos != null) null)
    "--enable-threads"
    (enFlag "ssl" (
      gnutls != null
      && libgcrypt != null) null)
    (enFlag "pam" (pam != null) null)
    (enFlag "gnutls" (
      gnutls != null
      && libgcrypt != null) null)
    (enFlag "avahi" (avahi != null) null)
    "--disable-dnssd"
    "--disable-launchd"
    (enFlag "systemd" (systemd_lib != null) null)
    #"--enable-page-logging"
    #"--enable-browsing"
    #"--enable-default-shared"
    "--enable-raw-printing"
    #"--enable-webif"
    # "--with-dbusdir$out/etc/dbus-1"
    "--with-components=all"
    # --with-cachedir
    # --with-icondir
    # --with-menudir
    # --with-fontpath
    # --with-logdir
    # --with-rundir=/run/cups
    # XXX: flag is not a proper boolean, build fails with optim enabled
    #"--without-optim"
    (wtFlag "systemd" (systemd_lib != null) null)
    "--with-languages=all"
    # --with-cups-user=lp
    # --with-cups-group=lp
    # --with-system-groups=lpadmin
    # FIXME: add java support
    "--without-java"
    "--without-perl"
    "--without-php"
    (wtFlag "python" (python2 != null) null)
  ];

  preInstall = ''
    installFlagsArray+=(
      # Don't try to write in /var at build time.
      "CACHEDIR=$TMPDIR"
      "LOGDIR=$TMPDIR"
      "REQUESTS=$TMPDIR"
      "STATEDIR=$TMPDIR"

      # Idem for /etc.
      "PAMDIR=$out/etc/pam.d"
      "DBUSDIR=$out/etc/dbus-1"
      "XINETD=$out/etc/xinetd.d"
      "SERVERROOT=$out/etc/cups"

      # Idem for /usr.
      "MENUDIR=$out/share/applications"
      "ICONDIR=$out/share/icons"
    )
  '';

  installFlags = [
    # Work around a Makefile bug.
    # FIXME: figure out what the issue was and if it is still valid
    "CUPS_PRIMARY_SYSTEM_GROUP=root"
  ];

  postInstall = ''
    # Delete obsolete stuff that conflicts with cups-filters.
    rm -rf $out/share/cups/banners $out/share/cups/data/testprint

    # Rename systemd files provided by CUPS
    for f in $out/lib/systemd/system/*; do
      sed -i "$f" \
        -e 's/org.cups.cupsd/cups/g' \
        -e 's/org.cups.//g'

      if [[ "$f" =~ .*cupsd\..* ]] ; then
        mv "$f" "''${f/org\.cups\.cupsd/cups}"
      else
        mv "$f" "''${f/org\.cups\./}"
      fi
    done

    # Use xdg-open
    sed -i $out/share/applications/cups.desktop \
      -e 's/Exec=htmlview/Exec=xdg-open/g'
  '';

  passthru = {
    inherit version;

    srcVerification = fetchurl rec {
      inherit (src)
        outputHash
        outputHashAlgo
        urls;
      failEarly = true;
      pgpsigUrls = map (n: "${n}.sig") urls;
      pgpKeyFingerprint = "3737 FD0D 0E63 B301 7244  0D2D DBA3 A7AB 08D7 6223";
    };
  };

  meta = with stdenv.lib; {
    homepage = https://cups.org/;
    description = "A standards-based printing system for UNIX";
    license = with licenses; [
      gpl2
      lgpl2
    ];
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
