{ stdenv
, fetchurl
, meson
, ninja

, systemd-dummy
}:

stdenv.mkDerivation rec {
  name = "fuse-3.2.1";

  src = fetchurl {
    url = "https://github.com/libfuse/libfuse/releases/download/${name}/"
      + "${name}.tar.xz";
    hashOutput = false;
    sha256 = "524d5360a5a243a9579c4b5a8330a3ddd3176375fbfea417ce6b8b3db6aea273";
  };

  nativeBuildInputs = [
    meson
    ninja
  ];

  postPatch = ''
    # Don't build unecessary stuff
    echo -n "" | tee {example,doc,test}/meson.build

    # Fix hardcoded paths
    sed -i lib/mount_util.c \
      -e 's@/bin/@/run/current-system/sw/bin/@g'

    # Can't chmod / chown in a nix-build
    sed -i 's,\(chmod\|chown\|mknod\|mkdir\),true,g' util/install_helper.sh
    sed -i "s,\".*/etc/init.d,\"$TMPDIR," util/install_helper.sh
  '';

  buildInputs = [
    systemd-dummy
  ];

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.asc") src.urls;
      pgpKeyFingerprint = "ED31 791B 2C5C 1613 AF38  8B8A D113 FCAC 3C4E 599F";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    description = "Kernel module and library for filesystems in user space";
    homepage = http://fuse.sourceforge.net/;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
