{ stdenv
, fetchurl

, libcap
, libgpg-error
, pth
}:

let
  tarballUrls = version: [
    "mirror://gnupg/libgcrypt/libgcrypt-${version}.tar.bz2"
  ];

  version = "1.7.6";
in
stdenv.mkDerivation rec {
  name = "libgcrypt-${version}";

  src = fetchurl {
    url = tarballUrls version;
    hashOutput = false;
    sha256 = "626aafee84af9d2ce253d2c143dc1c0902dda045780cc241f39970fc60be05bc";
  };

  buildInputs = [
    #libcap  Breaks application not expecting it
    libgpg-error
    #pth  Currently Broken
  ];

  configureFlags = [
    "--without-capabilities"
    "--disable-random-daemon"
  ];

  # Make sure includes are fixed for callers who don't use libgpgcrypt-config
  postInstall = ''
    sed -i 's,#include <gpg-error.h>,#include "${libgpg-error}/include/gpg-error.h",g' $out/include/gcrypt.h
  '';

  doCheck = true;

  passthru = {
    srcVerification = fetchurl rec {
      failEarly = true;
      urls = tarballUrls "1.7.6";
      pgpsigUrls = map (n: "${n}.sig") urls;
      pgpKeyFingerprints = [
        # Werner Koch
        "D869 2123 C406 5DEA 5E0F  3AB5 249B 39D2 4F25 E3B6"
        # NIIBE Yutaka
        "031E C253 6E58 0D8E A286  A9F2 2071 B08A 33BD 3F06"
      ];
      outputHash = "626aafee84af9d2ce253d2c143dc1c0902dda045780cc241f39970fc60be05bc";
      inherit (src) outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    homepage = https://www.gnu.org/software/libgcrypt/;
    description = "General-pupose cryptographic library";
    license = licenses.lgpl2Plus;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
