{ stdenv
, autoconf
, automake
, fetchurl
, intltool

, python2
, python2Packages
}:

stdenv.mkDerivation rec {
  name = "mpdris2-${version}";
  version = "0.7";

  src = fetchurl {
    url = "https://github.com/eonpatapon/mpDris2/archive/${version}.tar.gz";
    sha256 = "095swrjw59lh8qiwmjjjdbxl9587axilkj4mh2sx5m0kiq929z21";
  };

  nativeBuildInputs = [
    autoconf
    automake
    intltool
  ];

  buildInputs = [
    python2
    python2Packages.dbus
    python2Packages.mpd
    python2Packages.pygtk
    python2Packages.notify
    python2Packages.wrapPython
  ];

  preConfigure = ''
    ./autogen.sh
  '';

  postInstall = "wrapPythonPrograms";

  meta = with stdenv.lib; {
    description = "MPRIS 2 support for mpd";
    homepage = https://github.com/eonpatapon/mpDris2/;
    license = licenses.gpl3;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
