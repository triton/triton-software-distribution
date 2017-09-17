{ stdenv
, fetchurl
, gettext
, intltool
, lib
, python

, glib
, glib-networking
, gobject-introspection
, kerberos
, libxml2
, sqlite
, vala

, channel
}:

let
  inherit (lib)
    boolEn
    boolWt;

  sources = {
    "2.60" = {
      version = "2.60.0";
      sha256 = "b324edbecda0884143c0853b4a2bd5bd37fb3761f12f293c621ff34b9acdc84c";
    };
  };
  source = sources."${channel}";
in
stdenv.mkDerivation rec {
  name = "libsoup-${source.version}";

  src = fetchurl {
    url = "mirror://gnome/sources/libsoup/${channel}/${name}.tar.xz";
    hashOutput = false;
    inherit (source) sha256;
  };

  nativeBuildInputs = [
    gettext
    intltool
    python
  ];

  buildInputs = [
    glib
    gobject-introspection
    kerberos
    libxml2
    sqlite
    vala
  ];

  postPatch = ''
    patchShebangs ./libsoup/
  '';

  # glib-networking is a runtime dependency, not a compile-time dependency
  configureFlags = [
    "--disable-debug"
    "--enable-glibtest"
    "--disable-installed-tests"
    "--disable-always-build-tests"
    "--enable-nls"
    "--disable-gtk-doc"
    "--disable-gtk-doc-html"
    "--disable-gtk-doc-pdf"
    "--${boolEn (gobject-introspection != null)}-introspection"
    "--${boolEn (vala != null)}-vala"
    "--disable-tls-check"
    "--disable-code-coverage"
    "--enable-more-warnings"
    "--with-gnome"
    "--without-apache-httpd"
    "--${boolWt (kerberos != null)}-gssapi"
  ];

  postInstall = "rm -rvf $out/share/gtk-doc";

  passthru = {
    propagatedUserEnvPackages = [
      glib-networking
    ];

    srcVerification = fetchurl {
      inherit (src)
        outputHash
        outputHashAlgo
        urls;
      sha256Url = "https://download.gnome.org/sources/libsoup/${channel}/"
        + "${name}.sha256sum";
      failEarly = true;
    };
  };

  meta = with lib; {
    description = "An HTTP library implementation in C";
    homepage = https://wiki.gnome.org/Projects/libsoup;
    license = licenses.lgpl2Plus;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
