{ stdenv
, nukeReferences
, cpio
, readelf
, glibc
, coreutils
, bash
, findutils
, diffutils
, gnused
, gnugrep
, gawk
, gnutar
, gzip
, bzip2
, xz
, gnumake
, gnupatch
, patchelf
, curl
, gcc
, pkgconfig
, binutils
, busybox
}:

rec {
  build = stdenv.mkDerivation {
    name = "stdenv-bootstrap-tools";

    nativeBuildInputs = [
      nukeReferences
      cpio
    ];

    buildCommand = ''
      set -x
      mkdir -p $out/bin $out/lib $out/libexec
    '' +
    /* Copy what we need of Glibc. */ ''
      cp -d ${glibc}/lib/*.a $out/lib

      cp -rL ${glibc}/include $out
      chmod -R u+w $out/include
    '' +
    /* Hopefully we won't need these. */ ''
      rm -rf $out/include/mtd $out/include/rdma $out/include/sound $out/include/video
      find $out/include -name .install -exec rm {} \;
      find $out/include -name ..install.cmd -exec rm {} \;
      mv $out/include $out/include-glibc
    '' +
    /* Copy coreutils, bash, etc. */ ''
      cp ${coreutils}/bin/* $out/bin
      (cd $out/bin && rm vdir dir sha*sum pinky factor pathchk runcon shuf who whoami shred users)

      cp ${bash}/bin/bash $out/bin
      cp ${findutils}/bin/find $out/bin
      cp ${findutils}/bin/xargs $out/bin
      cp -d ${diffutils}/bin/* $out/bin
      cp -d ${gnused}/bin/* $out/bin
      cp -d ${gnugrep}/bin/grep $out/bin
      cp ${gawk}/bin/gawk $out/bin
      cp -d ${gawk}/bin/awk $out/bin
      cp ${gnutar}/bin/tar $out/bin
      cp ${gzip}/bin/gzip $out/bin
      cp ${bzip2}/bin/bzip2 $out/bin
      cp ${xz}/bin/xz $out/bin
      cp -d ${gnumake}/bin/* $out/bin
      cp -d ${gnupatch}/bin/* $out/bin
      cp ${patchelf}/bin/* $out/bin
      cp ${curl}/bin/curl $out/bin
      cp ${pkgconfig}/bin/pkg-config $out/bin
    '' +
    /* Copy what we need of GCC. */ ''
      cp -d ${gcc}/bin/gcc $out/bin
      cp -d ${gcc}/bin/cpp $out/bin
      cp -d ${gcc}/bin/g++ $out/bin
      cp -rd ${gcc}/lib/gcc $out/lib
      chmod -R u+w $out/lib
      rm -f $out/lib/gcc/*/*/include*/linux
      rm -f $out/lib/gcc/*/*/include*/sound
      rm -rf $out/lib/gcc/*/*/include*/root
      rm -f $out/lib/gcc/*/*/include-fixed/asm
      rm -rf $out/lib/gcc/*/*/plugin
      #rm -f $out/lib/gcc/*/*/*.a
      cp -rd ${gcc}/libexec/* $out/libexec
      chmod -R u+w $out/libexec
      rm -rf $out/libexec/gcc/*/*/plugin
      mkdir $out/include
      cp -rd ${gcc}/include/c++ $out/include
      chmod -R u+w $out/include
      rm -rf $out/include/c++/*/ext/pb_ds
      rm -rf $out/include/c++/*/ext/parallel
    '' +
    /* Copy binutils. */ ''
      for i in as ld ar ranlib nm strip readelf objdump; do
        cp ${binutils}/bin/$i $out/bin
      done
    '' +
    /* Copy all of the needed libraries for the binaries */ ''
      copy_libs_in_elf() {
        local BIN; local RELF; local RPATH; local LIBS; local LIB; local LINK;
        BIN=$1
        # Determine what libraries are needed by the elf
        set +x
        RELF="$(${readelf} -a $BIN 2>&1)" || continue
        if RPATH="$(echo "$RELF" | grep rpath | sed 's,.*\[\([^]]*\)\].*,\1,')" &&
          LIBS="$(echo "$RELF" | grep 'Shared library' | sed 's,.*\[\([^]]*\)\].*,\1,')"; then
          set -x
          for LIB in $LIBS; do
            # Find the libraries on the system
            for LIBPATH in $(echo "$RPATH" | tr ':' ' '); do
              if [ -f "$LIBPATH/$LIB" ]; then
                LIB="$LIBPATH/$LIB"
                break
              fi
            done
            # Copy the library and possibly symlinks
            while [ ! -f "$out/lib/$(basename $LIB)" ]; do
              LINK="$(readlink $LIB)" || true
              if [ -z "$LINK" ]; then
                cp -pdv $LIB $out/lib
                copy_libs_in_elf $LIB
                break
              else
                ln -sv "$(basename $LINK)" "$out/lib/$(basename $LIB)"
                if [ "${LINK:0:1}" != "/" ]; then
                  LINK="$(dirname $LIB)/$LINK"
                fi
                LIB="$LINK"
              fi
            done
          done
        else
          set -x
          echo "ELF is not dynamic: $BIN" >&2
        fi
      }
      for BIN in $out/bin/* $out/libexec/gcc/*/*/*; do
        echo "Copying libs for bin $BIN"
        copy_libs_in_elf $BIN
      done

      chmod -R u+w $out
    '' +
    /* Strip executables even further. */ ''
      for i in $out/bin/* $out/libexec/gcc/*/*/*; do
          if test -x $i -a ! -L $i; then
              chmod +w $i
              strip -s $i || true
          fi
      done

      nuke-refs $out/bin/*
      nuke-refs $out/lib/*
      nuke-refs $out/libexec/gcc/*/*/*

      mkdir $out/.pack
      mv $out/* $out/.pack
      mv $out/.pack $out/pack

      mkdir $out/on-server
      tar cvfJ $out/on-server/bootstrap-tools.tar.xz -C $out/pack .
      cp ${busybox}/bin/busybox $out/on-server
      chmod u+w $out/on-server/busybox
      nuke-refs $out/on-server/busybox
    '';

    # The result should not contain any references (store paths) so
    # that we can safely copy them out of the store and to other
    # locations in the store.
    allowedReferences = [ ];
  };

  dist = stdenv.mkDerivation {
    name = "stdenv-bootstrap-dist";

    buildCommand = ''
      mkdir -p $out/nix-support
      echo "file tarball ${build}/on-server/bootstrap-tools.tar.xz" >> $out/nix-support/hydra-build-products
      echo "file busybox ${build}/on-server/busybox" >> $out/nix-support/hydra-build-products
    '';
  };

}
