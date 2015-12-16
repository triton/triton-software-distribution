{ fetchurl, stdenv, pkgconfig, cairo, xlibsWrapper, fontconfig, freetype, libsigcxx }:

stdenv.mkDerivation rec {
  name = "cairomm-1.12.0";

  src = fetchurl {
    url = "http://cairographics.org/releases/${name}.tar.gz";
    sha256 = "1k3lb3jwnk5nm4s5cfm5kk8kl4b066chis4inws6k5yxdzn5lhsh";
  };

  buildInputs = [ pkgconfig ];

  propagatedBuildInputs = [ cairo xlibsWrapper fontconfig freetype libsigcxx ];

  meta = with stdenv.lib; {
    description = "A 2D graphics library with support for multiple output devices";

    longDescription = ''
      Cairo is a 2D graphics library with support for multiple output
      devices.  Currently supported output targets include the X
      Window System, Quartz, Win32, image buffers, PostScript, PDF,
      and SVG file output.  Experimental backends include OpenGL
      (through glitz), XCB, BeOS, OS/2, and DirectFB.

      Cairo is designed to produce consistent output on all output
      media while taking advantage of display hardware acceleration
      when available (e.g., through the X Render Extension).
    '';

    homepage = http://cairographics.org/;

    license = with licenses; [ lgpl2Plus mpl10 ];
  };
}
