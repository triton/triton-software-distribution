{ stdenv
, fetchurl

, xz
}:

stdenv.mkDerivation rec {
  name = "orc-0.4.25";

  src = fetchurl rec {
    url = "https://gstreamer.freedesktop.org/src/orc/${name}.tar.xz";
    sha256Url = "${url}.sha256sum";
    sha256 = "c1b1d54a58f26d483f0b3881538984789fe5d5460ab8fab74a1cacbd3d1c53d1";
  };

  buildInputs = [
    xz
  ];

  postPatch =
    /* Completely disable examples */ ''
      sed -i Makefile.{am,in} \
        -e '/SUBDIRS/ s:examples::'
    '';

  configureFlags = [
    "--disable-maintainer-mode"
    "--disable-gtk-doc"
    "--disable-gtk-doc-html"
    "--disable-gtk-doc-pdf"
    #"--enable-backend=all"
    "--enable-Bsymbolic"
  ];

  meta = with stdenv.lib; {
    description = "The Oil Runtime Compiler";
    homepage = "http://code.entropywave.com/orc/";
    # The source code implementing the Marsenne Twister algorithm is licensed
    # under the 3-clause BSD license. The rest is 2-clause BSD license.
    license = with licenses; [
      bsd2
      bsd3
    ];
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
