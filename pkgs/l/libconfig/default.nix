{ stdenv
, autoreconfHook
, bison
, fetchFromGitHub
, flex
, texinfo
}:

let
  version = "1.7.2";
in
stdenv.mkDerivation rec {
  name = "libconfig-${version}";

  src = fetchFromGitHub {
    version = 6;
    owner = "hyperrealm";
    repo = "libconfig";
    rev = "v${version}";
    sha256 = "c7832f304eb3ab7d3423a9f18bc475e5700083e2a68e04970abc27896ecb9516";
  };

  nativeBuildInputs = [
    autoreconfHook
    bison
    flex
    texinfo
  ];

  postPatch = ''
    # Remove autogenerated files
    for file in $(find . -name \*.y -or -name \*.l); do
      rm -vf "''${file:0:-2}".{c,h}
    done
    rm -r m4 aux-build config.* ac_config.h.in
    find . -name Makefile.in -delete

    # Don't build tests
    sed -i '/SUBDIRS/s, [^ ]*test[^ ]*,,g' Makefile.am

    # Fix ylwrap not adding scanner.h generation dependent on scanner.l
    sed -i '1ascanner.h: scanner.c' lib/Makefile.am
  '';

  configureFlags = [
    "--disable-examples"
  ];

  postInstall = ''
    rm -r "$out"/share
  '';

  meta = with stdenv.lib; {
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
