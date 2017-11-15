/* This function provides a generic Python package builder.  It is
 * intended to work with packages that use `distutils/setuptools`
 * (http://pypi.python.org/pypi/setuptools/), which represents a
 * large number of Python packages nowadays.
 */

{ python
, ensureNewerSourcesHook
, lib
, pip
, setuptools
, unzip
, wheel
, wrapPython
}:

{ name

# package name prefix, e.g. `python3.3-`${name}
, namePrefix ? python.libPrefix + "-"

, buildInputs ? [ ]

# propagate build dependencies so in case we have A -> B -> C,
# C can import package A propagated by B
, propagatedBuildInputs ? [ ]

# passed to "python setup.py build_ext"
# https://github.com/pypa/pip/issues/881
, configureFlags ? [ ]

# disable tests by default
, doCheck ? false

, pythonPath ? [ ]

# used to disable derivation, useful for specific python versions
, disabled ? false

, meta ? { }

# Execute before shell hook
, preShellHook ? ""

# Execute after shell hook
, postShellHook ? ""

# Additional arguments to pass to the makeWrapper function, which wraps
# generated binaries.
, makeWrapperArgs ? [ ]

, ... } @ attrs:

let
  inherit (lib)
    concatStringsSep
    hasSuffix
    optional
    optionalString;
in

# Keep extra attributes from `attrs`, e.g., `patchPhase', etc.

assert disabled ->
  throw "`${name}` is not supported for interpreter `${python.executable}`";

let
  # For backwards compatibility, let's use an alias
  doInstallCheck = doCheck;
in

python.stdenv.mkDerivation (builtins.removeAttrs attrs ["disabled" "doCheck"] // {
  name = namePrefix + name;

  buildInputs = [
    wrapPython
  ] ++ [
    (ensureNewerSourcesHook { year = "1980"; })
  ] ++ buildInputs
    ++ pythonPath
    ++ (optional (hasSuffix "zip" attrs.src.name or "") unzip);

  # propagate python/setuptools to active setup-hook in nix-shell
  propagatedBuildInputs = propagatedBuildInputs ++ [
    pip
    python
    setuptools
    wheel
  ];

  pythonPath = pythonPath;

  configurePhase = attrs.configurePhase or ''
    runHook preConfigure

    # Enables writing null timestamps when compiling python files so
    # that python doesn't try to update them when we freeze timestamps.
    # See python-2.7-deterministic-build.patch for more information.
    export DETERMINISTIC_BUILD=1

    runHook postConfigure
  '';

  buildPhase = attrs.buildPhase or ''
    runHook preBuild
    runHook postBuild
  '';

  installPhase = attrs.installPhase or ''
    runHook preInstall

    # Add current output to PYTHONPATH so applications can be run within the
    # current derivation.
    export PYTHONPATH="$out/${python.sitePackages}:$PYTHONPATH"

    # Copy the file into the build directory so it's executed relative to
    # the root of the source.  Many project make assumptions by using
    # relative paths.
    cp -v ${./run_setup.py} nix_run_setup.py

    mkdir -pv unique_wheel_dir
    ${python.interpreter} nix_run_setup.py ${
      optionalString (configureFlags != []) (
        "build_ext " + (concatStringsSep " " configureFlags)
      )
    } bdist_wheel --dist-dir=unique_wheel_dir

    pip -v install unique_wheel_dir/*.whl \
      --no-index --prefix="$out" --no-cache --build pipUnpackTmp --no-compile

    # pip hardcodes references to the build directory in compiled files so
    # we compile all files manually.
    ${python.interpreter} -c "
    import compileall
    try:
      # Python 3.2+ support optimization
      compileall.compile_dir('$out/${python.sitePackages}', optimize=2)
    except:
      compileall.compile_dir('$out/${python.sitePackages}')
    "

    runHook postInstall
  '';

  # We run all tests after software has been installed since that is
  # a common idiom in Python
  doInstallCheck = doInstallCheck;

  installCheckPhase = attrs.checkPhase or ''
    runHook preCheck

    ${python.interpreter} nix_run_setup.py test

    runHook postCheck
  '';

  postFixup = attrs.postFixup or ''
    wrapPythonPrograms

    # Fail if two packages with the same name are found in the closure.
    ${python.interpreter} ${./catch_conflicts.py}
  '';

  shellHook = attrs.shellHook or ''
    ${preShellHook}
    if test -e setup.py ; then
       tmp_path=$(mktemp -d)
       export PATH="$tmp_path/bin:$PATH"
       export PYTHONPATH="$tmp_path/${python.sitePackages}:$PYTHONPATH"
       mkdir -pv $tmp_path/${python.sitePackages}
       pip -v install -e . --prefix $tmp_path
    fi
    ${postShellHook}
  '';

  # FIXME: build directory currently gets hardcoded in .pyc files
  #buildDirCheck = attrs.buildDirCheck or false;

  meta = with lib.maintainers; {
    # default to python's platforms
    platforms = python.meta.platforms;
  } // meta // {
    maintainers = meta.maintainers or [ ];
    # a marker for release utilities to discover python packages
    isBuildPythonPackage = python.meta.platforms;
  };
})
