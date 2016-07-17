{ stdenv
, fetchurl

, libogg
}:

let
  inherit (stdenv.lib)
    enFlag;
in

stdenv.mkDerivation rec {
  name = "flac-1.3.1";

  src = fetchurl {
    url = "http://downloads.xiph.org/releases/flac/${name}.tar.xz";
    sha256 = "4773c0099dba767d963fd92143263be338c48702172e8754b9bc5103efe1c56c";
  };

  configureFLags = [
    "--enable-option-checking"
    "--enable-largefile"
    "--enable-asm-optimizations"
    "--disable-debug"
    "--enable-sse"  # X86 Only, we need this fixed at some point
    "--disable-altivec"  # Power Architecture
    "--disable-thorough-tests"
    "--disable-exhaustive-tests"
    "--disable-werror"
    "--disable-stack-smash-protection"
    "--disable-valgrind-testing"
    "--disable-doxygen-docs"
    "--disable-local-xmms-plugin"
    "--enable-xmms-plugin"
    "--enable-cpplibs"
    "--enable-ogg"
    "--disable-oggtest"
    "--enable-rpath"
  ];

  buildInputs = [
    libogg
  ];

  outputs = [
    "out"
    "doc"
  ];

  doCheck = false;
  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "FLAC lossless audio file format";
    homepage = http://xiph.org/flac/;
    license = with licenses; [
      bsd3
      fdl12
      gpl2
      lgpl21
    ];
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
