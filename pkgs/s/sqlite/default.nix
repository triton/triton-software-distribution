{ stdenv
, fetchurl

, readline
, ncurses
, zlib
}:

let
  inherit (stdenv.lib)
    fixedWidthString
    head
    splitString
    tail;

  version = "3.23.1";
  releaseYear = "2018";
  versionList = splitString "." version;
  version' = "${head versionList}${fixedWidthString 2 "0" (head (tail versionList))}"
    + "${fixedWidthString 2 "0" (head (tail (tail versionList)))}00";
in
stdenv.mkDerivation rec {
  name = "sqlite-${version}";

  src = fetchurl {
    url = "https://sqlite.org/${releaseYear}/sqlite-autoconf-${version'}.tar.gz";
    multihash = "QmTkRCN78j4uStNybmiNqWX2y4PKRfFZvYxX8w6Q6eyzaJ";
    hashOutput = false;
    sha256 = "92842b283e5e744eff5da29ed3c69391de7368fccc4d0ee6bf62490ce555ef25";
  };

  buildInputs = [
    readline
    ncurses
    zlib
  ];

  configureFlags = [
    "--enable-fts5"
    "--enable-json1"
    "--enable-session"
  ];

  NIX_CFLAGS_COMPILE = [
    "-DSQLITE_ENABLE_COLUMN_METADATA"
    "-DSQLITE_ENABLE_DBSTAT_VTAB"
    "-DSQLITE_ENABLE_JSON1"
    "-DSQLITE_ENABLE_FTS3"
    "-DSQLITE_ENABLE_FTS3_PARENTHESIS"
    "-DSQLITE_ENABLE_FTS4"
    "-DSQLITE_ENABLE_FTS5"
    "-DSQLITE_ENABLE_RTREE"
    "-DSQLITE_ENABLE_STMT_SCANSTATUS"
    "-DSQLITE_ENABLE_UNLOCK_NOTIFY"
    "-DSQLITE_SOUNDEX"
    "-DSQLITE_SECURE_DELETE"
  ];

  # Test for features which may not be available at compile time
  preBuild = ''
    # Use pread(), pread64(), pwrite(), pwrite64() functions for better performance if they are available.
    if cc -Werror=implicit-function-declaration -x c - -o "$TMPDIR/pread_pwrite_test" <<< \
      ''$'#include <unistd.h>\nint main()\n{\n  pread(0, NULL, 0, 0);\n  pwrite(0, NULL, 0, 0);\n  return 0;\n}'; then
      export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -DUSE_PREAD"
    fi
    if cc -Werror=implicit-function-declaration -x c - -o "$TMPDIR/pread64_pwrite64_test" <<< \
      ''$'#include <unistd.h>\nint main()\n{\n  pread64(0, NULL, 0, 0);\n  pwrite64(0, NULL, 0, 0);\n  return 0;\n}'; then
      export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -DUSE_PREAD64"
    elif cc -D_LARGEFILE64_SOURCE -Werror=implicit-function-declaration -x c - -o "$TMPDIR/pread64_pwrite64_test" <<< \
      ''$'#include <unistd.h>\nint main()\n{\n  pread64(0, NULL, 0, 0);\n  pwrite64(0, NULL, 0, 0);\n  return 0;\n}'; then
      export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -DUSE_PREAD64 -D_LARGEFILE64_SOURCE"
    fi
  '';

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      sha1Confirm = "0edbfd75ececb95e8e6448d6ff33df82774c9646";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    homepage = http://www.sqlite.org/;
    description = "A self-contained, serverless, zero-configuration, transactional SQL database engine";
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
