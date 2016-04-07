{ stdenv
, fetchurl
# Required
, boost
, icu
, libmpdclient
, ncurses
, readline
# Optional
, curl # Lyric fetching
, fftw_double # Visualizer screen
, taglib # Tag editor screen
, outputsSupport ? false # outputs screen
, clockSupport ? false # clock screen
}:

let
  inherit (stdenv.lib)
    enFlag
    wtFlag;
in

stdenv.mkDerivation rec {
  name = "ncmpcpp-0.7.3";

  src = fetchurl {
    url = "http://ncmpcpp.rybczak.net/stable/${name}.tar.bz2";
    sha256 = "04mj6r0whikliblxfbz92pibwcd7a3ywkryf01a89zd4bi1jk2rc";
  };

  buildInputs = [
    boost
    curl
    fftw_double
    icu
    libmpdclient
    ncurses
    readline
    taglib
  ];

  configureFlags = [
    "BOOST_LIB_SUFFIX="
    (enFlag "outputs" outputsSupport null)
    (enFlag "visualizer" (fftw_double != null) null)
    (enFlag "clock" clockSupport null)
    "--enable-unicode"
    (wtFlag "curl" (curl != null) null)
    (wtFlag "fftw" (fftw_double != null) null)
    "--without-pdcurses"
    (wtFlag "taglib" (taglib != null) null)
  ];

  meta = with stdenv.lib; {
    description = "A featureful ncurses based MPD client inspired by ncmpc";
    homepage = http://ncmpcpp.rybczak.net/;
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}
