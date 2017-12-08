{ stdenv
, autoconf
, automake
, fetchFromGitHub
, libtool
}:

let
  version = "1.0.2";

  tarFlags = [
    "--sort=name"
    "--owner=0"
    "--group=0"
    "--numeric-owner"
    "--no-acls"
    "--no-selinux"
    "--no-xattrs"
    "--mode=go=rX,u+rw,a-s"
    "--clamp-mtime"
  ];

  xzFlags = [
    "-v"
    "-9"
    "-e"
  ];

  inherit (stdenv.lib)
    concatStringsSep;
in
stdenv.mkDerivation {
  name = "brotli-dist-${version}";

  src = fetchFromGitHub {
    version = "3";
    owner = "google";
    repo = "brotli";
    rev = "v${version}";
    sha256 = "03dc8ed0b9edca466776f6bf0b56f091695bf6b3a6c3d819de4beea505241223";
  };
  
  nativeBuildInputs = [
    autoconf
    automake
    libtool
  ];

  preConfigure = ''
    ./bootstrap
  '';

  preBuild = ''
    # Fix bug in the handling of tar flags so we can prepend our own
    grep -q 'tar} chof' Makefile
    sed -i 's,tar} chof,tar} -chof,' Makefile

    buildFlagsArray+=(
      "XZ_OPT=${concatStringsSep " " xzFlags}"
      "TAR=tar ${concatStringsSep " " tarFlags} --mtime=@$SOURCE_DATE_EPOCH"
    )
  '';

  buildFlags = [
    "dist-xz"
  ];

  installPhase = ''
    mkdir -p "$out"
    mv brotli-*.tar* "$out"

    # Make sure the dist builds a valid tarball
    tar tf "$out"/* | grep '^brotli.*/configure$'
  '';
}
