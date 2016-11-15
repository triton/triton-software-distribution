{ stdenv
, fetchurl

, xz
, zlib
}:

let
  name = "kexec-tools-2.0.13";

  tarballUrls = [
    "mirror://kernel/linux/utils/kernel/kexec/${name}.tar"
    "http://horms.net/projects/kexec/kexec-tools/${name}.tar"
  ];
in
stdenv.mkDerivation rec {
  inherit name;

  src = fetchurl {
    urls = map (n: "${n}.xz") tarballUrls;
    hashOutput = false;
    sha256 = "874baf421171dbfca0084af2da71ccf5a67749dd2a27c3023da5f72460bae5cc";
  };

  buildInputs = [
    xz
    zlib
  ];

  configureFlags = [
    "--with-lzma"
    "--with-zlib"
  ];

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      pgpsigUrl = map (n: "${n}.sign") tarballUrls;
      pgpDecompress = true;
      pgpKeyFingerprint = "E27C D9A1 F5AC C2FF 4BFE  7285 D7CF 6469 6A37 4FBE";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    homepage = http://horms.net/projects/kexec/kexec-tools;
    description = "Tools related to the kexec Linux feature";
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
