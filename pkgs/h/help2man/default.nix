{ stdenv
, fetchurl
, gettext
, perlPackages
, makeWrapper
}:

let
  version = "1.47.5";

  tarballUrls = version: [
    "mirror://gnu/help2man/help2man-${version}.tar.xz"
  ];
in
stdenv.mkDerivation rec {
  name = "help2man-${version}";

  src = fetchurl {
    urls = tarballUrls version;
    hashOutput = false;
    sha256 = "7ca60b2519fdbe97f463fe2df66a6188d18b514bfd44127d985f0234ee2461b1";
  };

  nativeBuildInputs = [
    makeWrapper
    perlPackages.perl
    gettext
  ];

  postInstall = ''
    wrapProgram "$out/bin/help2man" \
      --prefix PERL5LIB : "$(echo ${perlPackages.LocaleGettext}/${perlPackages.perl.libPrefix})"
  '';

  passthru = {
    srcVerification = fetchurl rec {
      failEarly = true;
      urls = tarballUrls "1.47.5";
      pgpsigUrls = map (n: "${n}.sig") urls;
      pgpKeyFingerprint = "87EA 44D1 50D8 9615 E39A  3FEE F0DC 8E00 B28C 5995";
      inherit (src) outputHashAlgo;
      outputHash = "7ca60b2519fdbe97f463fe2df66a6188d18b514bfd44127d985f0234ee2461b1";
    };
  };

  meta = with stdenv.lib; {
    description = "Generate man pages from `--help' output";
    homepage = http://www.gnu.org/software/help2man/;
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}
