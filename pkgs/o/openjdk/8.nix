{ stdenv
, fetchurl

, alsa-lib
, bootjdk
, cacert
, cpio
, cups
, file
, fontconfig
, freetype
, liberation-fonts
, perl
, unzip
, which
, xorg
, zip
, zlib

, setJavaClassPath
, minimal ? false
, enableInfinality ? true # font rendering patch
}:

let
  inherit (stdenv)
    targetSystem;
  inherit (stdenv.lib)
    elem
    platforms;

  /**
   * JRE libraries are in architecture specific directories.
   */
  architecture =
    if elem targetSystem platforms.i686-linux then
      "i386"
    else if elem targetSystem platforms.x86_64-linux then
      "amd64"
    else
      throw "openjdk requires i686-linux or x86_64-linux";

  update = "122";
  build = "03";

  baseurl = "http://hg.openjdk.java.net/jdk8u/jdk8u";
  repover = "jdk8u${update}-b${build}";

  fetchjava = name: sha256: fetchurl {
    name = "${repover}-${name}.tar.gz";
    url = "${baseurl}/${name}/archive/${repover}.tar.gz";
    insecureHashOutput = true;
    inherit sha256;
  };

  openjdk8 = stdenv.mkDerivation {
    name = "openjdk-8u${update}b${build}";

    srcs = [
      (fetchjava "" "d5689617e8701e3db3ec93525642dc273715ab876edf7c11be32e971627c7168")
      (fetchjava "langtools" "9da834a96a5bb8ab53df9168c1393286b81a2adba1bda611d86cea0ac21f2ff5")
      (fetchjava "hotspot" "c9de908ec5c609ba3767ddacd4834e24b001cf3bb8c69ed9aba7709c1f99e0ff")
      (fetchjava "corba" "d07eb405155e05f35f15f49f3ac28b94ad8c0ebb1ff11144b7eed3cb4df422f6")
      (fetchjava "jdk" "523044ec3522584d4ae420b7569f44eeadeae202560efa22268335642a672907")
      (fetchjava "jaxws" "4bf372da731135d01b3c593596ce0728ca125a1e7131d70d5856fe84ede67f10")
      (fetchjava "jaxp" "9bc0c44d04031e39f01788fc6d90a49ecc319de6511d455fbb16894dd4e5abf9")
      (fetchjava "nashorn" "30aabd07070ac7eb65224f713c3ffc82eeaae99c35cfa369b198c600b95b7705")
    ];

    sourceRoot = ".";

    outputs = [ "out" "jre" ];

    buildInputs = [
      alsa-lib
      bootjdk
      cpio
      cups
      file
      fontconfig
      freetype
      liberation-fonts
      perl
      which
      unzip
      xorg.inputproto
      xorg.kbproto
      xorg.libICE
      xorg.libSM
      xorg.libX11
      xorg.libXcursor
      xorg.libXext
      xorg.libXi
      xorg.libXinerama
      xorg.libXrender
      xorg.libXt
      xorg.libXtst
      xorg.lndir
      xorg.renderproto
      xorg.xextproto
      xorg.xproto
      zip
      zlib
    ];

    prePatch = ''
      ls | grep jdk | grep -v '^jdk8u' | awk -F- '{print $1}' | \
      while read p; do
        mv $p-* $(ls | grep '^jdk8u')/$p
      done
      cd $(ls | grep '^jdk8u')
    '';

    patches = [
      ./fix-java-home-jdk8.patch
      ./read-truststore-from-env-jdk8.patch
      ./currency-date-range-jdk8.patch
    ] ++ (if enableInfinality then [
      ./004_add-fontconfig.patch
      ./005_enable-infinality.patch
    ] else [ ]);

    preConfigure = ''
      chmod +x configure
      sed -i configure \
        -e "s,/bin/bash,$shell,"
      sed -i hotspot/make/linux/adlc_updater \
        -e "s,/bin/sh,$shell,"
    '';

    configureFlags = [
      "--with-freetype=${freetype}"
      "--with-boot-jdk=${bootjdk.home}"
      "--with-update-version=${update}"
      "--with-build-number=${build}"
      "--with-milestone=fcs"
      "--enable-unlimited-crypto"
      "--disable-debug-symbols"
      "--disable-freetype-bundling"
    ] ++ (if minimal then [
      "--disable-headful"
      "--with-zlib=bundled"
      "--with-giflib=bundled"
    ] else [
      "--with-zlib=system"
    ]);

    # GCC 6 Fixes
    NIX_CFLAGS_COMPILE = [
      # FIXME: only pass C++ standard to C++ compiler, NIX_CFLAGS_COMPILE
      #        does not differentiate between C & C++.  OpenJDK's build
      #        system does not respect passing CXXFLAGS correctly and
      #        sometimes misuses CFLAGS in place of CXXFLAGS. The
      #        current solution is to pass the C++ standard to both the
      #        C & C++ compiler and ignore the errors about an invalid
      #        C standard in the mean time until a better solution is
      #        proposed.
      # https://bugzilla.redhat.com/show_bug.cgi?id=1306558
      # http://hg.openjdk.java.net/jdk9/dev/rev/9d77f922d694
      # http://mail.openjdk.java.net/pipermail/build-dev/2016-March/016767.html
      # NOTE: This should be fixed in OpenJDK-9 (both gcc6 and CFLAGS vs.
      #       CXXFLAGS)
      "-std=gnu++98"
      "-fno-delete-null-pointer-checks"
      "-fno-lifetime-dse"
      "-Wno-error"
    ];

    NIX_LDFLAGS = if minimal then null else "-lfontconfig";

    buildFlags = "all";

    installPhase = ''
      mkdir -p $out/lib/openjdk $out/share $jre/lib/openjdk

      cp -av build/*/images/j2sdk-image/* $out/lib/openjdk

      # Move some stuff to top-level.
      mv $out/lib/openjdk/include $out/include
      mv $out/lib/openjdk/man $out/share/man

      # jni.h expects jni_md.h to be in the header search path.
      ln -s $out/include/linux/*_md.h $out/include/

      # Remove some broken manpages.
      rm -rf $out/share/man/ja*

      # Remove crap from the installation.
      rm -rf $out/lib/openjdk/demo $out/lib/openjdk/sample

      # Move the JRE to a separate output and setup fallback fonts
      mv $out/lib/openjdk/jre $jre/lib/openjdk/
      mkdir $out/lib/openjdk/jre
      mkdir -p $jre/lib/openjdk/jre/lib/fonts/fallback
      lndir ${liberation-fonts}/share/fonts/truetype $jre/lib/openjdk/jre/lib/fonts/fallback
      lndir $jre/lib/openjdk/jre $out/lib/openjdk/jre

      rm -rf $out/lib/openjdk/jre/bina
      ln -s $out/lib/openjdk/bin $out/lib/openjdk/jre/bin

      # Make sure cmm/*.pf are not symlinks:
      # https://youtrack.jetbrains.com/issue/IDEA-147272
      rm -rf $out/lib/openjdk/jre/lib/cmm
      ln -s {$jre,$out}/lib/openjdk/jre/lib/cmm

      # Remove duplicate binaries.
      for i in $(cd $out/lib/openjdk/bin && echo *); do
        if [ "$i" = java ]; then continue; fi
        if cmp -s $out/lib/openjdk/bin/$i $jre/lib/openjdk/jre/bin/$i; then
          ln -sfn $jre/lib/openjdk/jre/bin/$i $out/lib/openjdk/bin/$i
        fi
      done

      # Generate certificates.
      pushd $jre/lib/openjdk/jre/lib/security
      rm cacerts
      perl ${./generate-cacerts.pl} $jre/lib/openjdk/jre/bin/keytool ${cacert}/etc/ssl/certs/ca-bundle.crt
      popd

      ln -s $out/lib/openjdk/bin $out/bin
      ln -s $jre/lib/openjdk/jre/bin $jre/bin
    '';

    # FIXME: this is unnecessary once the multiple-outputs branch is merged.
    preFixup = ''
      prefix=$jre stripDirs "$stripDebugList" "''${stripDebugFlags:--S}"
      patchELF $jre
      propagatedNativeBuildInputs+=" $jre"

      # Propagate the setJavaClassPath setup hook from the JRE so that
      # any package that depends on the JRE has $CLASSPATH set up
      # properly.
      mkdir -p $jre/nix-support
      echo -n "${setJavaClassPath}" > $jre/nix-support/propagated-native-build-inputs

      # Set JAVA_HOME automatically.
      mkdir -p $out/nix-support
      cat <<EOF > $out/nix-support/setup-hook
      if [ -z "\$JAVA_HOME" ]; then export JAVA_HOME=$out/lib/openjdk; fi
      EOF
    '';

    postFixup = ''
      # Build the set of output library directories to rpath against
      LIBDIRS=""
      for output in $outputs; do
        LIBDIRS="$(find $(eval echo \$$output) -name \*.so\* -exec dirname {} \; | sort | uniq | tr '\n' ':'):$LIBDIRS"
      done

      # Add the local library paths to remove dependencies on the bootstrap
      for output in $outputs; do
        OUTPUTDIR="$(eval echo \$$output)"
        BINLIBS="$(find $OUTPUTDIR/bin/ -type f; find $OUTPUTDIR -name \*.so\*)"
        echo "$BINLIBS" | while read i; do
          patchelf --set-rpath "$LIBDIRS:$(patchelf --print-rpath "$i")" "$i" || true
          patchelf --shrink-rpath "$i" || true
        done
      done

      # Test to make sure that we don't depend on the bootstrap
      for output in $outputs; do
        if grep -q -r '${bootjdk}' $(eval echo \$$output); then
          echo "Extraneous references to ${bootjdk} detected"
          exit 1
        fi
      done
    '';

    # Enabling optimizations breaks compilation
    fortifySource = false;
    optimize = false;

    # Explicitly does not support parallel building at all
    parallelBuild = false;
    parallelCheck = false;
    parallelInstall = false;

    passthru = {
      inherit architecture;
      home = "${openjdk8}/lib/openjdk";
    };

    meta = with stdenv.lib; {
      description = "The open-source Java Development Kit";
      homepage = http://openjdk.java.net/;
      license = licenses.gpl2;
      maintainers = with maintainers; [
        wkennington
      ];
      platforms = with platforms;
        x86_64-linux;
    };
  };
in openjdk8
