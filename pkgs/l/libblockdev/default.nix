{ stdenv
, autoconf
, automake
, fetchFromGitHub
, gobject-introspection
, libtool
, python2

, cryptsetup
, dmraid
, glib
, kmod
, libbytesize
, lvm2
, nss
, nspr
, parted
, systemd_lib
, util-linux_lib
, volume_key
}:

let
  version = "2.6";
in
stdenv.mkDerivation rec {
  name = "libblockdev-${version}";

  src = fetchFromGitHub {
    version = 2;
    owner = "rhinstaller";
    repo = "libblockdev";
    rev = "${version}-1";
    sha256 = "bb2fe6f39a378fb40fd3913673158f424618c1b026d9316dcb442b8bbd66310c";
  };

  nativeBuildInputs = [
    autoconf
    automake
    gobject-introspection
    libtool
    python2
  ];

  buildInputs = [
    cryptsetup
    dmraid
    glib
    kmod
    libbytesize
    lvm2
    nss
    nspr
    parted
    systemd_lib
    util-linux_lib
    volume_key
  ];

  postPatch = ''
    sed -i 's,pkg-config --atleast-version=3.2 libparted,pkg-config --atleast-version=3.3 libparted,' configure.ac
  '';

  preConfigure = ''
    patchShebangs autogen.sh
    ./autogen.sh

    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -I${volume_key}/include/volume_key"
  
    patchShebangs scripts/boilerplate_generator.py
  '';

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    "--disable-tests"
    "--without-python3"
    "--without-gtk-doc"
  ];

  preInstall = ''
    installFlagsArray+=(
      "sysconfdir=$out/etc"
      "localstatedir=$TMPDIR"
    )
  '';

  meta = with stdenv.lib; {
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
