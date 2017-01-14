{ stdenv
, bison
, fetchurl
, flex
, groff

, audit_lib
, coreutils
, cyrus-sasl
, openldap
, pam
, zlib
}:

stdenv.mkDerivation rec {
  name = "sudo-1.8.19p2";

  src = fetchurl {
    url = "https://www.sudo.ws/dist/${name}.tar.gz";
    multihash = "QmfSvF9bpmkviqCJxvGcTcxXm7RSh3ArfHmKtqhURYdT74";
    hashOutput = false;
    sha256 = "237e18e67c2ad59ecacfa4b7707198b09fcf84914621585a9bc670dcc31a52e0";
  };

  nativeBuildInputs = [
    bison
    flex
    groff
  ];

  buildInputs = [
    audit_lib
    cyrus-sasl
    openldap
    pam
    zlib
  ];

  configureFlags = [
    "--with-linux-audit"
    "--with-sssd"
    "--with-pam"
    "--with-logging=syslog"
    "--with-rundir=/run/sudo"
    "--with-vardir=/var/db/sudo"
    "--with-sendmail=/var/setuid-wrappers/sendmail"
    "--with-env-editor"
    "--with-ldap"
    "--enable-zlib"
    "--with-pam-login"
  ];

  postConfigure = ''
    cat >> pathnames.h <<'EOF'
      #undef _PATH_MV
      #define _PATH_MV "${coreutils}/bin/mv"
    EOF
    makeFlagsArray+=(
      "install_uid=$(id -u)"
      "install_gid=$(id -g)"
    )
    installFlagsArray+=(
      "sudoers_uid=$(id -u)"
      "sudoers_gid=$(id -g)"
      "sysconfdir=$out/etc"
      "rundir=$TMPDIR/dummy"
      "vardir=$TMPDIR/dummy"
    )
  '';

  postInstall = ''
    rm -f $out/share/doc/sudo/ChangeLog
  '';

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.sig") src.urls;
      pgpKeyFingerprint = "CCB2 4BE9 E948 1B15 D341  5953 5A89 DFA2 7EE4 70C4";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    description = "A command to run commands as root";
    homepage = http://www.sudo.ws/;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
