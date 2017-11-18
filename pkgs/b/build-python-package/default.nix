/* This function provides a generic Python package builder.  It is
 * intended to work with packages that use `distutils/setuptools`
 * (http://pypi.python.org/pypi/setuptools/), which represents a
 * large number of Python packages nowadays.
 */

{ python
, ensureNewerSourcesHook
, isPy2
, lib
, newBootstrap
, pip
, setuptools
, wheel
, wrapPython

# package name prefix, e.g. `python3.3-`${name}
, namePrefix ? python.libPrefix + "-"

# These interfaces are only here so that they could be declared
# in buildPythonPackage's callPackage. Do NOT use here.
, appdirs
, packaging
, pyparsing
, six
}:

{ name

, nativeBuildInputs ? [ ]

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

assert disabled ->
  throw "`${name}` is not supported for interpreter `${python.executable}`";

let
  inherit (lib)
    concatStringsSep
    hasSuffix
    optional
    optionalString;

  # For backwards compatibility, let's use an alias
  doInstallCheck = doCheck;
in

python.stdenv.mkDerivation (builtins.removeAttrs attrs ["disabled" "doCheck"] // {
  name = namePrefix + name;

  nativeBuildInputs = [
    pip
    wheel
    wrapPython
  ] ++ nativeBuildInputs;

  buildInputs = [
    (ensureNewerSourcesHook { year = "1980"; })
  ] ++ buildInputs
    ++ pythonPath;

  propagatedBuildInputs = [
    python
    setuptools  # Required by namespaced packages at runtime.
  ] ++ propagatedBuildInputs;

  pythonPath = pythonPath;

  configurePhase = attrs.configurePhase or ''
    runHook preConfigure

    # Enables writing null timestamps when compiling python files so
    # that python doesn't try to update them when we freeze timestamps.
    # See python-2.7-deterministic-build.patch for more information.
    export DETERMINISTIC_BUILD=1

    # A lot of projects make the assumption that the install site-packages
    # directory has already been added to the site path.
    export PYTHONPATH="$out/${python.sitePackages}:$PYTHONPATH"

    runHook postConfigure
  '';

  buildPhase = attrs.buildPhase or ''
    runHook preBuild

    # Copy the file into the build directory so it's executed relative to
    # the root of the source.  Many project make assumptions by using
    # relative paths.
    # NOTE: This just imports setuptools for every setup.py file so that we
    #       don't use distutils even if it is hardcoded in the setup.py.
    cp -v ${./run_setup.py} nix_run_setup.py

    mkdir -pv unique_dist_dir
    ${python.interpreter} nix_run_setup.py ${
      optionalString (configureFlags != []) (
        "build_ext " + (concatStringsSep " " configureFlags)
      )
    } bdist_wheel --dist-dir=unique_dist_dir/

    runHook postBuild
  '';

  installPhase = attrs.installPhase or ''
    runHook preInstall

    # TODO: install wheel file to another output

    pushd unique_dist_dir/
    ${python.interpreter} -m pip -v install *.whl \
      --prefix=$out \
      --build pipUnpackTmp \
      --ignore-installed \
      --no-cache \
      --no-compile \
      --no-deps \
      --no-index
    popd

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
  '' + /* pip hardcodes references to the build directory in compiled files
          so we compile all files manually. */ ''
    ${python.interpreter} -c "
    import compileall
    try:
      # Python 3.2+ support optimization
      compileall.compile_dir('$out/${python.sitePackages}', optimize=1)
    except:
      compileall.compile_dir('$out/${python.sitePackages}')
    "
  '' + /* Fail if two packages with the same name are found in the closure */ ''
    ${python.interpreter} ${./catch_conflicts.py}
  '' + optionalString (isPy2 && newBootstrap)
    /* FIXME: codyopel
       I seem to have broken pth loading for python 2 and possibly python 3
       and I haven't figured out why yet. As a result namespaced packages fail
       to load on python 2 because they rely on setuptools' pth shim file to
       set syspath. This is a hack in the meantime to write __init__.py files
       in the directories of packages returned by setup.py's
       namespace_packages to fix importing with python 2.  Python 3 supports
       implicit namespaces so it isn't obvious if pth loading is broken on
       python 3. */ ''
    if grep -q 'namespace_packages=' setup.py && \
        [ -n "$(grep -oP 'namespace_packages=\[.*\]' setup.py)" ]; then
    ${python.interpreter} -c "
    import os

    # FIXME: could be cleaner if there is a way to use setuptools to
    #        return this list.
    $(grep -oP 'namespace_packages=\[.*\]' setup.py)  # returns namespace_packages=[]
    for package in namespace_packages:
      moduledir = '$out/${python.sitePackages}/' + package
      initfile = moduledir + '/__init__.py'
      if not os.path.exists(initfile) and os.path.isdir(moduledir):
        open(initfile, 'a').close()
    "
    fi
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

  meta = with lib.maintainers; {
    # default to python's platforms
    platforms = python.meta.platforms;
  } // meta // {
    maintainers = meta.maintainers or [ ];
    # a marker for release utilities to discover python packages
    isBuildPythonPackage = python.meta.platforms;
  };
})
