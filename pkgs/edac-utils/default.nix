{ stdenv
, fetchFromGitHub
, makeWrapper
, perl

, dmidecode
, kmod
, sysfsutils
}:

stdenv.mkDerivation {
  name = "edac-utils-2015-07-11";

  src = fetchFromGitHub {
    owner = "grondo";
    repo = "edac-utils";
    rev = "556ebce6e1a5a8ad8c07090979a36be7a2276e2e";
    sha256 = "edb15c5139c47e8be5d6493140424e54daf2818e044ec12402c778faf2b1a9ab";
  };

  nativeBuildInputs = [
    makeWrapper
    perl
  ];

  buildInputs = [
    sysfsutils
  ];

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
  ];

  preInstall = ''
    installFlagsArray+=("sysconfdir=$out/etc")
  '';

  postInstall = ''
    wrapProgram "$out/sbin/edac-ctl" \
      --set PATH : "" \
      --prefix PATH : "${dmidecode}/bin" \
      --prefix PATH : "${kmod}/bin"
  '';

  meta = with stdenv.lib; {
    homepage = http://github.com/grondo/edac-utils;
    description = "Handles the reporting of hardware-related memory errors";
    license = licenses.gpl2;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
