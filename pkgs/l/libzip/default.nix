{ stdenv
, fetchurl
, lib
, perl

, bzip2
, zlib
}:

stdenv.mkDerivation rec {
  name = "libzip-1.4.0";

  src = fetchurl {
    url = "https://www.nih.at/libzip/${name}.tar.xz";
    multihash = "QmR2W6cHF673qWFRChQvFu8fGHf3i6fm3A9iRPtHQjvceb";
    sha256 = "e508aba025f5f94b267d5120fc33761bcd98440ebe49dbfe2ed3df3afeacc7b1";
  };

  nativeBuildInputs = [
    perl
  ];

  buildInputs = [
    bzip2
    zlib
  ];

  preInstall = ''
    patchShebangs man/handle_links
  '';

  meta = with lib; {
    homepage = https://www.nih.at/libzip;
    description = "A C library for reading, creating and modifying zip archives";
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
