{ stdenv
, fetchTritonPatch
, fetchurl
, perl
, which
, patchelf

, bash
, iana-etc
, mime-types
, tzdata

, channel
}:

let

  inherit ((import ./sources.nix)."${channel}")
    version
    sha256
    sha256Bootstrap
    patches;

  goPlatform =
    if stdenv.hostSystem == "x86_64-linux" then
      "linux-amd64"
    else
      throw "Unsupported System";

  goBootstrap = stdenv.mkDerivation {
    name = "go-bootstrap";

    src = fetchurl {
      url = "https://storage.googleapis.com/golang/go${channel}.${goPlatform}.tar.gz";
      hashOutput = false;
      sha256 = sha256Bootstrap."${stdenv.hostSystem}";
    };

    nativeBuildInputs = [
      patchelf
    ];

    buildPhase = ''
      strip bin/*
      find bin -type f -exec patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" {} \;
    '';

    installPhase = ''
      mkdir -p $out/share
      ln -s .././ $out/share/go
      cp -r bin src pkg $out

      # Test that the install worked
      $out/bin/go help
    '';
  };

  inherit (stdenv.lib)
    optionalString
    versionOlder;
in
stdenv.mkDerivation {
  name = "go-${version}";

  src = fetchurl {
    url = "https://storage.googleapis.com/golang/go${version}.src.tar.gz";
    inherit sha256;
  };

  # perl is used for testing go vet
  nativeBuildInputs = [
    perl
    which
  ];

  # I'm not sure what go wants from its 'src', but the go installation manual
  # describes an installation keeping the src.
  preUnpack = ''
    mkdir -p $out/share
    cd $out/share
  '';

  prePatch = ''
    # Ensure that the source directory is named go
    cd ..
    if [ ! -d go ]; then
      mv * go
    fi

    cd go
  '';

  patches = map (p: fetchTritonPatch p) patches;

  postPatch = ''
    patchShebangs ./ # replace /bin/bash

    # The os test wants to read files in an existing path. Just don't let it be /usr/bin.
    sed -i 's,/usr/bin,'"`pwd`", src/os/os_test.go
    sed -i 's,/bin/pwd,'"`type -P pwd`", src/os/os_test.go

    # Don't run tests by default
    sed -i '/run.bash/d' src/all.bash

    sed -i '\#"/etc/mime.types",#i"${mime-types}/etc/mime.types",' src/mime/type_unix.go
    sed -i 's,/etc/protocols,${iana-etc}/etc/protocols,g' src/net/lookup_unix.go
    sed -i 's,/etc/services,${iana-etc}/etc/services,g' src/net/port_unix.go src/net/parse_test.go
    sed -i '\#"/usr/share/zoneinfo/",#i"${tzdata}/share/zoneinfo/",' src/time/zoneinfo_unix.go
  '' + optionalString (versionOlder version "1.7") ''
    # We need to fix shebangs which will be used in an output script
    # We can't use patch shebangs because this is an embedded script fix
    sed -i 's,#!/usr/bin/env bash,#! ${stdenv.shell},g' misc/cgo/testcarchive/test.bash
  '';

  GOOS = "linux";
  GOARCH =
    if stdenv.system == "i686-linux" then
      "386"
    else if stdenv.system == "x86_64-linux" then
      "amd64"
    else
      throw "Unsupported system.";
  GO386 = 387; # from Arch: don't assume sse2 on i686
  CGO_ENABLED = 1;
  GOROOT_BOOTSTRAP = "${goBootstrap}/share/go";

  # These optimizations / security hardenings break the `os` library
  optimize = false;
  fortifySource = false;

  installPhase = ''
    mkdir -p "$out/bin"
    export GOROOT="$(pwd)/"
    export GOBIN="$out/bin"
    export PATH="$GOBIN:$PATH"
    cd ./src
    echo Building
    ./all.bash

    find "$out/bin" -mindepth 1 -exec mv {} "$out/share/go/bin" \;
    rmdir "$out/bin"
    ln -sv share/go/bin "$out/bin"
  '';

  preFixup = ''
    rm -r $out/share/go/pkg/bootstrap
    rm -r $out/share/go/{doc,misc}
    find $out -type f \( -name run -or -name \*.bash -or -name \*.sh \) -delete
    rm -r $out/share/go/src/cmd/go/testdata

    while read exe; do
      strip $exe || true
      patchelf --shrink-rpath $exe || true
    done < <(find $out/share/ -executable -and -not -type d)

    TMPREP="$(printf "/%*s" "$(( ''${#TMPDIR} - 1))" | tr ' ' 'x')"
    while read file; do
      echo "Removing $TMPDIR from $file" >&2
      sed -i "s,$TMPDIR,$TMPREP,g" "$file"
    done < <(grep -r "$TMPDIR" $out | sed "s,.*\(''${out}[^ :]*\).*,\1,g" | sort | uniq)
  '';

  setupHook = ./setup-hook.sh;

  disallowedReferences = [
    bash
    goBootstrap
  ];

  meta = with stdenv.lib; {
    branch = channel;
    homepage = http://golang.org/;
    description = "The Go Programming language";
    license = licenses.bsd3;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
