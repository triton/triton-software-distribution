{ stdenv
, fetchurl
, gettext
, intltool

, db
, gcr
, glib
, gnome-online-accounts
, gobject-introspection
, gperf
, gsettings-desktop-schemas
, gtk3
, icu
, kerberos
, libaccounts-glib
, libgdata
, libgweather
, libical
, libsecret
, libsoup
, libxml2
, openldap
, nspr
, nss
, p11_kit
, python
, sqlite
, vala
, zlib
}:

with {
  inherit (stdenv.lib)
    enFlag
    wtFlag;
};

stdenv.mkDerivation rec {
  name = "evolution-data-server-${version}";
  versionMajor = "3.20";
  versionMinor = "0";
  version = "${versionMajor}.${versionMinor}";

  src = fetchurl {
    url = "mirror://gnome/sources/evolution-data-server/${versionMajor}/" +
          "${name}.tar.xz";
    sha256 = "05f2e84fd5b02f9a526ffd549753af564f54c56047b5126aeecb28a8a0fa4f4b";
  };

  nativeBuildInputs = [
    gettext
    intltool
  ];

  buildInputs = [
    db
    gcr
    glib
    gnome-online-accounts
    gobject-introspection
    gperf
    gsettings-desktop-schemas
    gtk3
    icu
    kerberos
    libaccounts-glib
    libgdata
    libgweather
    libical
    libsecret
    libsoup
    libxml2
    nspr
    nss
    openldap
    p11_kit
    python
    sqlite
    vala
    zlib
  ];

  configureFlags = [
    "--enable-schemas-compile"
    "--disable-maintainer-mode"
    "--enable-nls"
    "--disable-code-coverage"
    "--disable-installed-tests"
    "--disable-gtk-doc"
    "--disable-gtk-doc-html"
    "--disable-gtk-doc-pdf"
    (enFlag "gtk" (gtk3 != null) null)
    # TODO: add google auth support
    "--disable-google-auth"
    "--disable-examples"
    (enFlag "goa" (gnome-online-accounts != null) null)
    # TODO: requires libsignon-glib (Ubuntu online accounts)
    "--disable-uoa"
    "--enable-backend-per-process"
    "--disable-backtraces"
    (enFlag "smime" (nss != null) null)
    "--enable-ipv6"
    (enFlag "weather" (libgweather != null) null)
    "--enable-dot-locking"
    "--enable-file-locking"
    "--disable-purify"
    "--enable-google"
    "--enable-largefile"
    "--enable-glibtest"
    (enFlag "introspection" (gobject-introspection != null) null)
    (enFlag "vala-bindings" (vala != null) null)
    # TODO: libphonenumber support
    "--without-phonenumber"
    "--without-private-docs"
    (wtFlag "libdb" (db != null) "${db}")
    (wtFlag "krb5" (kerberos != null) "${kerberos}")
    (wtFlag "openldap" (openldap != null) null)
    "--without-static-ldap"
    "--without-sunldap"
    "--without-static-sunldap"
  ];

  meta = with stdenv.lib; {
    description = "Evolution groupware backend";
    homepage = https://wiki.gnome.org/Apps/Evolution;
    license = with licenses; [
      lgpl2
      lgpl3
      bsd3
    ];
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };

}
