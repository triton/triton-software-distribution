{ stdenv
, fetchurl
, autoconf
, automake
, intltool

, argyllcms
, bashCompletion
, dbus
, glib
, gobject-introspection
, libgusb
, lcms2
, libgudev
, libusb
, polkit
, sqlite
, systemd_lib
, vala
}:

with {
  inherit (stdenv.lib)
    enFlag;
};

stdenv.mkDerivation rec {
  name = "colord-1.2.12";

  src = fetchurl {
    url = "http://www.freedesktop.org/software/colord/releases/${name}.tar.xz";
    sha256 = "0flcsr148xshjbff030pgyk9ar25an901m9q1pjgjdvaq5j1h96m";
  };

  nativeBuildInputs = [
    autoconf
    automake
    intltool
  ];

  buildInputs = [
    argyllcms
    bashCompletion
    dbus
    glib
    gobject-introspection
    lcms2
    libgudev
    libgusb
    libusb
    polkit
    sqlite
    systemd_lib
    vala
  ];

  preConfigure = ''
    configureFlagsArray+=(
      "--with-systemdsystemunitdir=$out/etc/systemd/system"
      "--with-udevrulesdir=$out/lib/udev/rules.d"
    )
  '';

  configureFlags = [
    (enFlag "introspection" (gobject-introspection != null) null)
    "--enable-schemas-compile"
    "--disable-gtk-doc"
    "--disable-gtk-doc-html"
    "--disable-gtk-doc-pdf"
    "--enable-nls"
    "--disable-strict"
    "--enable-rpath"
    (enFlag "libgusb" (libgusb != null) null)
    (enFlag "udev" (systemd_lib != null) null)
    "--disable-bash-completion"
    (enFlag "polkit" (polkit != null) null)
    "--enable-libcolordcompat"
    (enFlag "systemd-login" (systemd_lib != null) null)
    "--disable-examples"
    (enFlag "argyllcms-sensor" (argyllcms != null) null)
    "--disable-reverse"
    "--disable-sane"
    (enFlag "vala" (vala != null) null)
    "--disable-session-example"
    "--enable-print-profiles"
    "--disable-installed-tests"
    #"--with-daemon-user"
  ];

  postInstall = ''
    rm -rvf $out/var/lib/colord
    mkdir -p $out/etc/bash_completion.d
    cp -v ./data/colormgr $out/etc/bash_completion.d
  '';

  meta = with stdenv.lib; {
    description = "Accurately color manage input and output devices";
    homepage = http://www.freedesktop.org/software/colord/intro.html;
    license = licenses.lgpl2Plus;
    maintainers = with maintainers; [ ];
    platforms = with platforms;
      x86_64-linux;
  };
}
