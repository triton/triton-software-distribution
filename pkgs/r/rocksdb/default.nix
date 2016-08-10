{ stdenv
, fetchFromGitHub
, perl

, bzip2
, google-gflags
, jemalloc
, lz4
, numactl
, snappy
, zlib
, zstd
}:

let
  version = "4.9";
in
stdenv.mkDerivation rec {
  name = "rocksdb-${version}";

  src = fetchFromGitHub {
    owner = "facebook";
    repo = "rocksdb";
    rev = "v${version}";
    sha256 = "008a5d793c9ef7df3486b2dda8810ccae409e59b0c08a72c8c75aa3b782e0cf3";
  };

  nativeBuildInputs = [
    perl
  ];

  buildInputs = [
    bzip2
    google-gflags
    jemalloc
    lz4
    numactl
    snappy
    zlib
    zstd
  ];

  postPatch = ''
    # Hack to fix typos
    sed -i 's,#inlcude,#include,g' build_tools/build_detect_platform
  '';

  # Environment vars used for building certain configurations
  PORTABLE = "1";
  USE_SSE = "1";
  CMAKE_CXX_FLAGS = "-std=gnu++11";
  JEMALLOC_LIB = "-ljemalloc";

  makeFlags = [
    "DEBUG_LEVEL=0"
  ];

  buildFlags = [
    "shared_lib"
    "static_lib"
  ];

  installFlags = [
    "INSTALL_PATH=\${out}"
  ];

  installTargets = [
    "install-shared"
    "install-static"
  ];

  postInstall = ''
    # Might eventually remove this when we are confident in the build process
    echo "BUILD CONFIGURATION FOR SANITY CHECKING"
    cat make_config.mk
  '';

  meta = with stdenv.lib; {
    homepage = http://rocksdb.org;
    description = "A library that provides an embeddable, persistent key-value store for fast storage";
    license = licenses.bsd3;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
