{ stdenv
, fetchurl
, gettext

, cairo
, gdk-pixbuf
, glib
, gobject-introspection
, gst-plugins-base
, gstreamer
, libdrm
, mesa_noglu
, pango
, wayland
, xorg
}:

let
  inherit (stdenv.lib)
    enFlag
    optionalString;

  versionMajor = "1.22";
  versionMinor = "0";
  version = "${versionMajor}.${versionMinor}";
in

stdenv.mkDerivation rec {
  name = "cogl-${version}";

  src = fetchurl {
    url = "mirror://gnome/sources/cogl/${versionMajor}/${name}.tar.xz";
    sha256 = "14daxqrid5039xmq9yl4pk86awng1n9zgl6ysblhc4gw2ifzp7b8";
  };

  nativeBuildInputs = [
    gettext
  ];

  buildInputs = [
    cairo
    gdk-pixbuf
    glib
    gobject-introspection
    gst-plugins-base
    gstreamer
    libdrm
    mesa_noglu
    pango
    wayland
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
  ];

  postPatch =
    /* Don't build examples */ ''
      sed -i Makefile.{am,in} \
        -e "s/^\(SUBDIRS +=.*\)examples\(.*\)$/\1\2/"
    '' +
    /* Fix library name in pkg-config file */ ''
      sed -i cogl-pango/cogl-pango-2.0-experimental.pc.in \
        -e 's|-lcoglpango|-lcogl-pango|'
    '' + optionalString (!doCheck)
    /* The configure switch does not completely disable
       tests from being built */ ''
      sed -i Makefile.{am,in} \
        -e "s/^\(SUBDIRS =.*\)test-fixtures\(.*\)$/\1\2/" \
        -e "s/^\(SUBDIRS +=.*\)tests\(.*\)$/\1\2/" \
        -e "s/^\(.*am__append.* \)tests\(.*\)$/\1\2/"
    '';

  configureFlags = [
    "--disable-installed-tests"
    #"--enable-emscripten"
    "--disable-standalone"
    "--disable-debug"
    (enFlag "unit-tests" doCheck null)
    (enFlag "cairo" (cairo != null) null)
    "--disable-profile"
    "--disable-maintainer-flags"
    "--enable-deprecated"
    (enFlag "glibtest" (glib != null) null)
    (enFlag "glib" (glib != null) null)
    (enFlag "cogl-pango" (pango != null) null)
    (enFlag "cogl-gst" (gstreamer != null && gst-plugins-base != null) null)
    "--enable-cogl-path"
    (enFlag "gdk-pixbuf" (gdk-pixbuf != null) null)
    "--disable-quartz-image"
    "--disable-examples-install"
    "--enable-gles1"
    "--enable-gles2"
    "--enable-gl"
    "--enable-cogl-gles2"
    "--enable-glx"
    "--disable-wgl"
    "--enable-null-egl-platform"
    "--disable-gdl-egl-platform"
    "--enable-wayland-egl-platform"
    "--enable-kms-egl-platform"
    "--enable-wayland-egl-server"
    "--disable-android-egl-platform"
    "--disable-mir-egl-platform"
    "--enable-xlib-egl-platform"
    "--disable-gtk-doc"
    "--disable-gtk-doc-html"
    "--disable-gtk-doc-pdf"
    "--enable-nls"
    "--enable-rpath"
    (enFlag "introspection" (gobject-introspection != null) null)
    "--with-x"
  ];

  doCheck = false;

  meta = with stdenv.lib; {
    description = "2D graphics library with support for multiple output devices";
    homepage = http://cairographics.org/;
    license = with licenses; [
      mpl11
      lgpl21
    ];
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
