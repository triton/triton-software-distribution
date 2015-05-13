{ stdenv, fetchurl, pkgconfig
, libffi, docbook_xsl, doxygen, graphviz, libxslt, xmlto, expat
}:

# Require the optional to be enabled until upstream fixes or removes the configure flag
assert expat != null;

with stdenv.lib;

stdenv.mkDerivation rec {
  name = "wayland-${version}";
  version = "1.7.0";

  src = fetchurl {
    url = "http://wayland.freedesktop.org/releases/${name}.tar.xz";
    sha256 = "173w0pqzk2m7hjlg15bymrx7ynxgq1ciadg03hzybxwnvfi4gsmx";
  };

  configureFlags = "--with-scanner --disable-documentation";

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [ libffi /* docbook_xsl doxygen graphviz libxslt xmlto */ expat ];

  meta = {
    description = "Reference implementation of the wayland protocol";
    homepage    = http://wayland.freedesktop.org/;
    license     = licenses.mit;
    platforms   = platforms.linux;
    maintainers = with maintainers; [ codyopel wkennington ];
  };

  passthru.version = version;
}
