{ stdenv
, fetchzip

, kernel
, libmnl
}:

let
  inherit (stdenv.lib)
    optionals
    optionalString;

  rev = "61e51e6312ac08b9041d6b736f49f10b8369bde6";
  date = "2017-04-21";
in
stdenv.mkDerivation {
  name = "wireguard-${date}${optionalString (kernel != null) "-${kernel.version}"}";

  src = fetchzip {
    version = 2;
    url = "https://git.zx2c4.com/WireGuard/snapshot/WireGuard-${rev}.tar.xz";
    multihash = "QmaSgvkpSrhwzypEFsvEuvjsFaziZqCGktsUk4fb7p3TWP";
    sha256 = "66989148ca3158fe328c2fe304fc08be4bee713f3c8bfa2cc060b73b3bb79fe9";
  };

  buildInputs = optionals (kernel == null) [
    libmnl
  ];

  preConfigure = ''
    cd src
  '';

  makeFlags = if kernel != null then [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ] else [
    "-C"
    "tools"
  ];

  buildFlags = optionals (kernel != null) [
    "modules"
  ];

  preBuild = ''
    makeFlagsArray+=("PREFIX=$out")
  '' + optionalString (kernel != null) ''
    makeFlagsArray+=(
      "M=$(pwd)"
      "INSTALL_MOD_PATH=$out"
      "INSTALL_MOD_STRIP=1"
    )
  '';

  installTargets = optionals (kernel != null) [
    "modules_install"
  ];

  # Kernel code doesn't support our hardening flags
  optFlags = kernel == null;
  pie = kernel == null;
  fpic = kernel == null;
  noStrictOverflow = kernel == null;
  fortifySource = kernel == null;
  stackProtector = kernel == null;
  optimize = kernel == null;

  meta = with stdenv.lib; {
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
