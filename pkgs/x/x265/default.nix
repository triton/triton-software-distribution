{ stdenv
, cmake
, fetchFromBitbucket
, fetchurl
, lib
, nasm
, ninja

, numactl

# Optionals
, cliSupport ? true # Build standalone CLI application

, unittestsSupport ? false # Unit tests

# Debugging options
, debugSupport ? false # Run-time sanity checks (debugging)
, werrorSupport ? false # Warnings as errors
, custatsSupport ? false # Internal profiling of encoder work

, channel
}:

let
  inherit (stdenv)
    targetSystem;
  inherit (lib)
    boolOn
    concatStringsSep
    elem
    optionals
    platforms;

  sources = {
    "stable" = {
      version = "2.7";
      multihash = "QmbFMke1KXqnYyBBWxB74N4c5SBnJMVAiMNRcGu6x1AwQH";
      sha256 = "d5e75fa62ffe6ed49e691f8eb8ab8c1634ffcc0725dd553c6fdb4d5443b494a2";
    };
    "head" = {
      fetchzipversion = 5;
      version = "2018-04-24";
      rev = "fde57c2996659ae2dd5aeddbdedbdb6dc52178e1";
      sha256 = "183d0f128d9273b7cc3e4984c9403ff338241760bbda47c030a52dda37bea6e9";
    };
  };
  source = sources."${channel}";

  src =
    if channel == "head" then
      fetchFromBitbucket {
        version = source.fetchzipversion;
        owner = "multicoreware";
        repo = "x265";
        inherit (source) rev sha256;
      }
    else
      fetchurl {
        url = "https://bitbucket.org/multicoreware/x265/downloads/"
          + "x265_${source.version}.tar.gz";
        inherit (source) multihash sha256;
      };

  cmakeFlagsAll = [
    "-DFPROFILE_GENERATE=OFF"
    "-DFPROFILE_USE=OFF"
    "-DNATIVE_BUILD=OFF"
    "-DCHECKED_BUILD=${boolOn debugSupport}"
    "-DENABLE_AGGRESSIVE_CHECKS=OFF"
    "-DENABLE_ASSEMBLY=ON"
    "-DENABLE_LIBNUMA=${boolOn (
      elem targetSystem platforms.linux
      && numactl != null)}"
      #"NO_ATOMICS"
    "-DENABLE_PIC=ON"
    "-DENABLE_AGGRESSIVE_CHECKS=OFF"
    "-DENABLE_ASSEMBLY=ON"
    "-DCHECKED_BUILD=OFF"
    "-DWARNINGS_AS_ERRORS=OFF"
    "-DENABLE_ALTIVEC=${boolOn (elem targetSystem platforms.powerpc-all)}"
    "-DCPU_POWER8=${boolOn (elem targetSystem platforms.powerpc-all)}"
    "-DENABLE_PPA=OFF"
    "-DENABLE_VTUNE=OFF"
    "-DDETAILED_CU_STATS=${boolOn custatsSupport}"
    "-DENABLE_TESTS=OFF"
  ];
in

assert (elem targetSystem platforms.linux) -> numactl != null;

/* By default, the compiled library is configured for only one
 * output bit depth.  Meaning, one has to rebuild libx265 if they
 * want to produce HEVC files with a different bit depth, which
 * is annoying.  However, upstream supports proper namespacing
 * for 8bit, 10bit & 12bit HEVC and linking all that together so
 * that the resulting library can produce all three of bit depths
 * instead of only one.  The API requires the bit depth parameter,
 * so that libx265 can then chose which variant of the encoder to use.  To
 * achieve this, we have to build one (static) library for each
 * non-main variant, and link it into the main library.  Upstream
 * documents using the 8bit variant as main library, hence we do not
 * allow disabling it: "main" *MUST* come last in the following list.
 */
let
  libx265-10 = stdenv.mkDerivation {
    name = "libx265-10-${source.version}";

    inherit src;

    cmakeFlags = [
      "-DENABLE_CLI=OFF"
      "-DENABLE_SHARED=OFF"
      "-DENABLE_HDR10_PLUS=ON"
      "-DEXPORT_C_API=OFF"
      "-DHIGH_BIT_DEPTH=ON"
      "-DLINKED_8BIT=OFF"
      "-DLINKED_10BIT=OFF"
      "-DLINKED_12BIT=OFF"
      "-DMAIN12=OFF"
    ] ++ cmakeFlagsAll;

    postUnpack = ''
      srcRoot="$srcRoot/source"
    '';

    postPatch = /* Work around to set version in the compiled binary */ ''
      sed -i cmake/version.cmake \
        -e '/X265_LATEST_TAG/s/0.0/${source.version}/g'
    '';

    nativeBuildInputs = [
      cmake
      nasm
      ninja
    ];

    buildInputs = optionals (elem targetSystem platforms.linux) [
      numactl
    ];

    postInstall =
      /* Remove unused files to prevent conflicts with
         pkg-config/libtool hooks */ ''
        rm -frv $out/includes
        rm -frv $out/lib/pkgconfig
      '' + /* Rename the library to a unique name */ ''
        mv -v $out/lib/libx265.a $out/lib/libx265_main10.a
      '';
  };
  libx265-12 = stdenv.mkDerivation {
    name = "libx265-12-${source.version}";

    inherit src;

    cmakeFlags = [
      "-DENABLE_CLI=OFF"
      "-DENABLE_SHARED=OFF"
      "-DENABLE_HDR10_PLUS=ON"
      "-DEXPORT_C_API=OFF"
      "-DHIGH_BIT_DEPTH=ON"
      "-DLINKED_8BIT=OFF"
      "-DLINKED_10BIT=OFF"
      "-DLINKED_12BIT=OFF"
      "-DMAIN12=ON"
    ] ++ cmakeFlagsAll;

    postUnpack = ''
      srcRoot="$srcRoot/source"
    '';

    postPatch = /* Work around to set version in the compiled binary */ ''
      sed -i cmake/version.cmake \
        -e '/X265_LATEST_TAG/s/0.0/${source.version}/g'
    '';

    nativeBuildInputs = [
      cmake
      nasm
      ninja
    ];

    buildInputs = optionals (elem targetSystem platforms.linux) [
      numactl
    ];

    postInstall =
      /* Remove unused files to prevent conflicts with
         pkg-config/libtool hooks */ ''
        rm -frv $out/includes
        rm -frv $out/lib/pkgconfig
      '' + /* Rename the library to a unique name */ ''
        mv -v $out/lib/libx265.a $out/lib/libx265_main12.a
      '';
  };
in
stdenv.mkDerivation rec {
  name = "x265-${source.version}";

  inherit src;

  nativeBuildInputs = [
    cmake
    nasm
    ninja
  ];

  buildInputs = [
    libx265-10
    libx265-12
  ] ++ optionals (elem targetSystem platforms.linux) [
    numactl
  ];

  postUnpack = ''
    srcRoot="$srcRoot/source"
  '';

  postPatch = /* Work around to set version in the compiled binary */ ''
    sed -i cmake/version.cmake \
      -e '/X265_LATEST_TAG/s/0.0/${source.version}/g'
  '';

  x265AdditionalLibs = [
    "${libx265-10}/lib/libx265_main10.a"
    "${libx265-12}/lib/libx265_main12.a"
  ];

  x265Libs = concatStringsSep ";" x265AdditionalLibs;

  cmakeFlags = [
    "-DENABLE_CLI=${boolOn cliSupport}"
    "-DENABLE_SHARED=ON"
    "-DHIGH_BIT_DEPTH=OFF"
    "-DENABLE_HDR10_PLUS=OFF"
    "-DLINKED_8BIT=OFF"
    "-DLINKED_10BIT=ON"
    "-DLINKED_12BIT=ON"
    #"NO_ATOMICS"
    "-DSTATIC_LINK_CRT=OFF"
    "-DEXPORT_C_API=ON"
    "-DEXTRA_LIB=${x265Libs}"
  ] ++ cmakeFlagsAll;

  postInstall = /* Remove static library */ ''
    rm -v $out/lib/libx265.a
  '';

  meta = with lib; {
    description = "Library for encoding h.265/HEVC video streams";
    homepage = http://x265.org;
    license = licenses.gpl2;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
