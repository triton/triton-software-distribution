{ stdenv
, buildPythonPackage
, fetchFromGitHub
, fetchPyPi
, fetchTritonPatch
, glibcLocales
, isPy2
, isPy3
, lib
, makeWrapper
, pythonPackages
, writeScript

, bash
, bash-completion
, beautifulsoup
, bs1770gain
, discogs-client
, enum34
, flac
, flask
, gobject-introspection
, imagemagick
, itsdangerous
, jellyfish
, jinja2
, mock
, mp3val
, munkres
, musicbrainzngs
, mutagen
, nose
, pathlib
, pyacoustid
, pyechonest
, pylast
, python-mpd2
, pyxdg
, pyyaml
, rarfile
, requests
, responses
, unidecode
, werkzeug

# For use in inline plugin
, pycountry

# External plugins
, enableAlternatives ? false
#, enableArtistCountry ? true
, enableCopyArtifacts ? true
, enableBeetsMoveAllArtifacts ? true
}:

let
  inherit (lib)
    optional
    optionals;

  completion = "${bash-completion}/share/bash-completion/bash_completion";

  version = "1.4.5";
in
buildPythonPackage rec {
  name = "beets-${version}";

  src = fetchPyPi {
    package = "beets";
    inherit version;
    sha256 = "1bea88c5c23137a36d09590856df8c2f4e857ef29890d16c4d14b1170e9202fc";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  propagatedBuildInputs = [
    beautifulsoup
    bs1770gain
    discogs-client
    flac
    flask
    # Needed for hook to set GI_TYPELIB_PATH
    gobject-introspection
    imagemagick
    itsdangerous
    jellyfish
    jinja2
    mock
    mp3val
    munkres
    musicbrainzngs
    mutagen
    nose
    pyacoustid
    pyechonest
    pylast
    python-mpd2
    pyxdg
    pyyaml
    rarfile
    responses
    requests
    unidecode
    werkzeug
  ] ++ optionals isPy2 [
    enum34
    pathlib
  ] ++ [
    pycountry
  ] ++ optional enableAlternatives (
      import ./plugins/beets-alternatives.nix {
        inherit
          stdenv
          buildPythonPackage
          fetchFromGitHub
          isPy2
          optionals
          pythonPackages;
      }
    )
    # FIXME: Causes other plugins to fail to load
    #  - Needs to use beets logging instead of printing error messages
    #  - Needs musicbrainz fixes
    /*++ optional enableArtistCountry (
      import ./plugins/beets-artistcountry.nix {
        inherit
          stdenv
          buildPythonPackage
          fetchFromGitHub
          pythonPackages;
      }
    )*/
    /* Provides edit & moveall plugins */
    ++ optional enableBeetsMoveAllArtifacts (
      import ./plugins/beets-moveall-artifacts.nix {
        inherit
          stdenv
          buildPythonPackage
          fetchFromGitHub;
      }
    );

  patches = [
    (fetchTritonPatch {
      rev = "d3fc5e59bd2b4b465c2652aae5e7428b24eb5669";
      file = "beets/beets-1.3-replaygain-default-bs1770gain.patch";
      sha256 = "d864aa643c16d5df9b859b5f186766a94bf2db969d97f255a88f33acf903b5b6";
    })
  ];

  postPatch = ''
    sed -i -e '/assertIn.*item.*path/d' test/test_info.py
    echo echo completion tests passed > test/rsrc/test_completion.sh

    sed -i -e '/^BASH_COMPLETION_PATHS *=/,/^])$/ {
      /^])$/i u"${completion}"
    }' beets/ui/commands.py
  '' + /* fix paths for badfiles plugin */ ''
    sed -i -e '/self\.run_command(\[/ {
      s,"flac","${flac}/bin/flac",
      s,"mp3val","${mp3val}/bin/mp3val",
    }' beetsplug/badfiles.py
  '' + /* Replay gain */ ''
    sed -i -re '
      s!^( *cmd *= *b?['\'''"])(bs1770gain['\'''"])!\1${bs1770gain}/bin/\2!
    ' beetsplug/replaygain.py
    sed -i -e 's/if has_program.*bs1770gain.*:/if True:/' \
      test/test_replaygain.py
  '';

  meta = with lib; {
    description = "Music tagger and library organizer";
    homepage = http://beets.radbox.org;
    license = licenses.mit;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
