/* This file contains various functions that take a stdenv and return
   a new stdenv with different behaviour, e.g. using a different C
   compiler. */

{dietlibc, fetchurl, runCommand}:
   
   
rec {


  # Override the compiler in stdenv for specific packages.
  overrideGCC = stdenv: gcc: stdenv //
    { mkDerivation = args: stdenv.mkDerivation (args // { NIX_GCC = gcc; });
    };

    
  # Add some arbitrary packages to buildInputs for specific packages.
  # Used to override packages in stenv like Make.  Should not be used
  # for other dependencies.
  overrideInStdenv = stdenv: pkgs: stdenv //
    { mkDerivation = args: stdenv.mkDerivation (args //
        { buildInputs = (if args ? buildInputs then args.buildInputs else []) ++ pkgs; }
      );
    };


  # Override the setup script of stdenv.  Useful for testing new
  # versions of the setup script without causing a rebuild of
  # everything.
  #
  # Example:
  #   randomPkg = import ../bla { ...
  #     stdenv = overrideSetup stdenv ../stdenv/generic/setup-latest.sh;
  #   };
  overrideSetup = stdenv: setup: stdenv.regenerate setup;


  # Return a modified stdenv that uses dietlibc to create small
  # statically linked binaries.
  useDietLibC = stdenv: stdenv //
    { mkDerivation = args: stdenv.mkDerivation (args // {
        NIX_CFLAGS_LINK = "-static";

        # libcompat.a contains some commonly used functions.
        NIX_LDFLAGS = "-lcompat";

        # These are added *after* the command-line flags, so we'll
        # always optimise for size.
        NIX_CFLAGS_COMPILE =
          (if args ? NIX_CFLAGS_COMPILE then args.NIX_CFLAGS_COMPILE else "")
          + " -Os -s -D_BSD_SOURCE=1";

        configureFlags =
          (if args ? configureFlags then args.configureFlags else "")
          + " --disable-shared"; # brrr...

        NIX_GCC = import ../build-support/gcc-wrapper {
          inherit stdenv;
          libc = dietlibc;
          inherit (stdenv.gcc) gcc binutils nativeTools nativePrefix;
          nativeLibc = false;
        };
      });
      isDietLibC = true;
    } // {inherit fetchurl;};

    
  # Return a modified stdenv that uses klibc to create small
  # statically linked binaries.
  useKlibc = stdenv: klibc: stdenv //
    { mkDerivation = args: stdenv.mkDerivation (args // {
        NIX_CFLAGS_LINK = "-static";

        # These are added *after* the command-line flags, so we'll
        # always optimise for size.
        NIX_CFLAGS_COMPILE =
          (if args ? NIX_CFLAGS_COMPILE then args.NIX_CFLAGS_COMPILE else "")
          + " -Os -s";

        configureFlags =
          (if args ? configureFlags then args.configureFlags else "")
          + " --disable-shared"; # brrr...

        NIX_GCC = runCommand "klibc-wrapper" {} ''
          ensureDir $out/bin
          ln -s ${klibc}/bin/klcc $out/bin/gcc
          ln -s ${klibc}/bin/klcc $out/bin/cc
          ensureDir $out/nix-support
          echo 'PATH=$PATH:${stdenv.gcc.binutils}/bin' > $out/nix-support/setup-hook
        '';
      });
      isKlibc = true;
      isStatic = true;
    } // {inherit fetchurl;};

    
  # Return a modified stdenv that tries to build statically linked
  # binaries.
  makeStaticBinaries = stdenv: stdenv //
    { mkDerivation = args: stdenv.mkDerivation (args // {
        NIX_CFLAGS_LINK = "-static";

        configureFlags =
          (if args ? configureFlags then args.configureFlags else "")
          + " --disable-shared"; # brrr...
      });
      isStatic = true;
    } // {inherit fetchurl;};


  /* Modify a stdenv so that the specified attributes are added to
     every derivation returned by its mkDerivation function.

     Example:
       stdenvNoOptimise =
         addAttrsToDerivation
           { NIX_CFLAGS_COMPILE = "-O0"; }
           stdenv;
  */
  addAttrsToDerivation = extraAttrs: stdenv: stdenv //
    { mkDerivation = args: stdenv.mkDerivation (args // extraAttrs); };


  /* Return a modified stdenv that builds packages with GCC's coverage
     instrumentation.  The coverage note files (*.gcno) are stored in
     $out/.coverage, along with the source code of the package, to
     enable programs like lcov to produce pretty-printed reports.
  */
  addCoverageInstrumentation = stdenv:
    addAttrsToDerivation
      { NIX_CFLAGS_COMPILE = "-O0 --coverage";

        prePhases = "moveBuildDir";
        postPhases = "cleanupBuildDir";

        # Object files instrumented with coverage analysis write
        # runtime coverage data to <path>/<object>.gcda, where <path>
        # is the location where gcc originally created the object
        # file.  That would be /tmp/nix-build-<something>, which will
        # be long gone by the time we run the program.  Furthermore,
        # the <object>.gcno files created at compile time are also
        # written there.  And to make nice coverage reports with lcov,
        # we need the source code.  So we move the whole build tree to
        # $out/.coverage.
        moveBuildDir =
          ''
            ensureDir $out/.coverage
            cd $out/.coverage
          '';

        # This is an uberhack to prevent libtool from removing gcno
        # files.  This has been fixed in libtool, but there are
        # packages out there with old ltmain.sh scripts.
        # See http://www.mail-archive.com/libtool@gnu.org/msg10725.html
        postUnpack =
          ''
            for i in $(find -name ltmain.sh); do
                substituteInPlace $i --replace '*.$objext)' '*.$objext | *.gcno)'
            done
          '';

        # Get rid of everything that isn't a gcno file or a C source
        # file.  This also includes the gcda files; we're not
        # interested in coverage resulting from the package's own test
        # suite.
        cleanupBuildDir =
          ''
             find $out/.coverage/ -type f -a ! \
               \( -name "*.c" -o -name "*.gcno" -o -name "*.h" \) \
               | xargs rm -f --
          '';
      }
      stdenv;
}
