{ stdenv
, fetchurl

, lzo
, ncurses
, openssl
, readline
, zlib

, channel ? "1.1"
}:

let
  inherit (stdenv.lib)
    optionals
    versionAtLeast;

  sources = {
    "1.0" = {
      version = "1.0.28";
      sha256 = "0b502699360f09ce2128a39cf02abca07bfc699fc02ce829b3a90cf5e1e8b344";
    };
    "1.1" = {
      version = "1.1pre14";
      sha256 = "e349e78f0e0d10899b8ab51c285bdb96c5ee322e847dfcf6ac9e21036286221f";
    };
  };
  source = sources."${channel}";
in
stdenv.mkDerivation rec {
  name = "tinc-${source.version}";

  src = fetchurl {
    url = "https://www.tinc-vpn.org/packages/${name}.tar.gz";
    allowHashOutput = false;
    inherit (source) sha256;
  };

  buildInputs = [
    lzo
    openssl
    zlib
  ] ++ optionals (versionAtLeast channel "1.1") [
    readline
    ncurses
  ];

  configureFlags = [
    "--localstatedir=/var"
    "--sysconfdir=/etc"
  ];

  passthru = {
    srcVerified = fetchurl {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.sig") src.urls;
      pgpKeyFingerprint = "D62B DD16 8EFB E48B C60E  8E23 4A60 84B9 C0D7 1F4A";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    description = "VPN daemon with full mesh routing";
    homepage="http://www.tinc-vpn.org/";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
