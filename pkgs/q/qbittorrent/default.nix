{ stdenv
, fetchFromGitHub
, fetchTritonPatch
, fetchurl
, lib
, which

, boost
, dbus
, libtorrent-rasterbar
, qt5
, zlib

, guiSupport ? false
, webuiSupport ? true

, channel ? "stable"
}:

assert guiSupport -> dbus != null;

let
  inherit (lib)
    boolEn
    optionals;

  sources = {
    stable = {
      version = "3.3.15";
      sha256 = "a7bbc08a39912a15a496702e736a98c083011bbb14fe5f04440880d7e6b2ceae";
    };
    head = {
      fetchzipversion = 3;
      version = "2017-08-14";
      rev = "ea749bb052cc866ca70876b213fb057ecd69f33e";
      sha256 = "dcdf4d98e6eaa04c05a34e8c03575015e4176ae448ab9523495d2eaa2aa380dd";
    };
  };
  source = sources."${channel}";
in
stdenv.mkDerivation rec {
  name = "qbittorrent-${source.version}";

  src =
    if channel != "head" then
      fetchurl {
        url = "mirror://sourceforge/qbittorrent/qbittorrent/${name}/${name}.tar.xz";
        hashOutput = false;
        inherit (source) sha256;
      }
    else
      fetchFromGitHub {
        version = source.fetchzipversion;
        owner = "qbittorrent";
        repo = "qbittorrent";
        inherit (source) rev sha256;
      };

  nativeBuildInputs = [
    which
  ];

  buildInputs = [
    boost
    dbus
    libtorrent-rasterbar
    qt5
    zlib
  ];

  postPatch = /* Our lrelease binary is named lrelease, not lrelease-qt5 */ ''
    sed -i qm_gen.pri \
      -e 's/lrelease-qt5/lrelease/'
  '';

  configureFlags = [
    "--disable-debug"
    "--${boolEn (guiSupport)}-gui"
    "--enable-systemd"
    "--${boolEn webuiSupport}-webui"
    "--${boolEn (dbus != null)}-qt-dbus"
    "--with-qtsingleapplication=shipped"
    "--with-boost=${boost.dev}"
    "--with-boost-libdir=${boost.lib}/lib"
    "--with-boost-system"
  ] ++ optionals (channel != "head") [
    "--without-qt4"
    "--with-qjson=system"
  ];

  passthru = {
    srcVerification = fetchurl {
      inherit (src)
        outputHash
        outputHashAlgo
        urls;
      failEarly = true;
      pgpsigUrls = map (n: "${n}.asc") src.urls;
      pgpKeyFingerprint = "D8F3 DA77 AAC6 7410 5359  9C13 6E4A 2D02 5B7C C9A2";
    };
  };

  meta = with lib; {
    description = "BitTorrent client in C++ and Qt";
    homepage = http://www.qbittorrent.org/;
    license = licenses.gpl2;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
