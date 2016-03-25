{ stdenv, fetchurl, makeWrapper, coreutils }:

stdenv.mkDerivation rec {
  name = "openresolv-3.7.3";

  src = fetchurl {
    url = "mirror://roy/openresolv/${name}.tar.xz";
    sha256 = "b3ee7960f8808c83ab4923ced3c4b114f1c0141367ab1c3d08765327c0782a02";
  };

  buildInputs = [ makeWrapper ];

  configurePhase =
    ''
      cat > config.mk <<EOF
      PREFIX=$out
      SYSCONFDIR=/etc
      SBINDIR=$out/sbin
      LIBEXECDIR=$out/libexec/resolvconf
      VARDIR=/var/run/resolvconf
      MANDIR=$out/share/man
      RESTARTCMD="false \1"
      EOF
    '';

  installFlags = "SYSCONFDIR=$(out)/etc";

  postInstall = ''
    wrapProgram "$out/sbin/resolvconf" --set PATH "${coreutils}/bin"
  '';

  meta = {
    description = "A program to manage /etc/resolv.conf";
    homepage = http://roy.marples.name/projects/openresolv;
    license = stdenv.lib.licenses.bsd2;
    maintainers = [ stdenv.lib.maintainers.eelco ];
    platforms = stdenv.lib.platforms.linux;
  };
}
