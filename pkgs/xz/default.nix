{ stdenv
, fetchurl
}:

stdenv.mkDerivation rec {
  name = "xz-5.2.2";

  src = fetchurl {
    url = "http://tukaani.org/xz/${name}.tar.bz2";
    sha256 = "1da071wyx921pyx3zkxlnbpp14p6km98pnp66mg1arwi9dxgbxbg";
  };

  # In stdenv-linux, prevent a dependency on bootstrap-tools.
  preConfigure = ''
    unset CONFIG_SHELL
  '';

  postInstall = ''
    rm -rf $out/share/doc
  '';

  dontDisableStatic = true;

  meta = with stdenv.lib; {
    homepage = http://tukaani.org/xz/;
    description = "XZ, general-purpose data compression software, successor of LZMA";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}
