{ stdenv
, curl
, nss
, perlPackages
}:

stdenv.mkDerivation rec {
  name = "nss-cacert-${nss.version}";

  src = nss.src;

  nativeBuildInputs = [
    perlPackages.perl
    perlPackages.LWP
  ];

  postPatch = ''
    unpackFile ${curl.src};
  '';

  buildPhase = ''
    perl curl-*/lib/mk-ca-bundle.pl -d "file://$(pwd)/nss/lib/ckfw/builtins/certdata.txt" ca-bundle.crt
  '';

  installPhase = ''
    mkdir -pv $out/etc/ssl/certs
    cp -v ca-bundle.crt $out/etc/ssl/certs
  '';

  meta = with stdenv.lib; {
    homepage = http://curl.haxx.se/docs/caextract.html;
    description = "A bundle of X.509 certificates of public Certificate Authorities (CA)";
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
