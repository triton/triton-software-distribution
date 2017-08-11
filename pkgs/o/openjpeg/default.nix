{ stdenv
, cmake
, fetchzip
, lib
, ninja

, lcms2
, libpng
, libtiff
, zlib

# MJ2 executables
, mj2Support ? false
# JPWL library & executables
, jpwlLibSupport ? false
# JPIP library & executables
, jpipLibSupport ? false
  , jdk
# JPIP Server
, jpipServerSupport ? false
  , curl
  , fcgi
# OPJViewer executable
, opjViewerSupport ? false
  , wxGTK
# Openjpeg jar (Java)
, openjpegJarSupport ? false
# JP3D comp
, jp3dSupport ? false

, channel
}:

assert jpipServerSupport ->
  jpipLibSupport
  && curl != null
  && fcgi != null;
assert opjViewerSupport -> wxGTK != null;
assert (openjpegJarSupport || jpipLibSupport) -> jdk != null;

let
  inherit (stdenv.lib)
    boolOn
    optional
    optionals
    optionalString
    versionAtLeast;

  sources = {
    # FIXME: drop 1.x when ffmpeg supports 2.x+
    "1" = {
      fetchzipversion = 2;
      version = "1.5.2";
      sha256 = "3ced2c9e5292024b045052385ae98127d786c76fe3b7289ab02ccb46d087bb34";
    };
    "2" = {
      fetchzipversion = 3;
      version = "2.2.0";
      sha256 = "d3a3007893a722b08cbe94b1c07e9a32b6426c08452341997a075d0a4bf3e8b5";
    };
  };
  source = sources."${channel}";
in
stdenv.mkDerivation rec {
  name = "openjpeg-${source.version}";

  src = fetchzip {
    version = source.fetchzipversion;
    url = "https://github.com/uclouvain/openjpeg/archive/"
      + "${if versionAtLeast channel "2" then "v" else "version."}"
      + "${source.version}.tar.gz";
    inherit (source) sha256;
  };

  nativeBuildInputs = [
    cmake
    ninja
  ];

  buildInputs = [
    lcms2
    libpng
    libtiff
    zlib
  ] ++ optionals jpipServerSupport [
    curl
    fcgi
  ] ++ optional opjViewerSupport [
    wxGTK
  ] ++ optionals (openjpegJarSupport || jpipLibSupport) [
    jdk
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DBUILD_CODEC=ON"
    "-DBUILD_MJ2=${boolOn mj2Support}"
    "-DBUILD_JPWL=${boolOn jpwlLibSupport}"
    "-DBUILD_JPIP=${boolOn jpipLibSupport}"
    "-DBUILD_JPIP_SERVER=${boolOn jpipServerSupport}"
    "-DBUILD_VIEWER=${boolOn opjViewerSupport}"
    "-DBUILD_VIEWER=OFF"
    "-DBUILD_JAVA=${boolOn openjpegJarSupport}"
    "-DBUILD_JP3D=${boolOn jp3dSupport}"
    "-DBUILD_THIRDPARTY=OFF"
    "-DBUILD_TESTING=OFF"
  ];

  passthru = {
    incDir = "openjpeg-${channel}";
  };

  meta = with lib; {
    description = "Open-source JPEG 2000 codec written in C language";
    homepage = http://www.openjpeg.org/;
    license = licenses.bsd2;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
