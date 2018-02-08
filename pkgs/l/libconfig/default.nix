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
    version = 5;
    owner = "hyperrealm";
    repo = "libconfig";
    rev = "v${version}";
    sha256 = "678e74b44702adf3428de35befd3c5624d11d1f6c38fc6e54d61f59f32bc7387";
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
