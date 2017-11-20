{ stdenv
, asciidoc
, fetchFromGitHub
, python
, re2c
}:

let
  version = "1.8.2";
in
stdenv.mkDerivation rec {
  name = "ninja-${version}";

  src = fetchFromGitHub {
    version = 3;
    owner = "ninja-build";
    repo = "ninja";
    rev = "v${version}";
    sha256 = "5203256f365945454e5309fdf9c9238e6014aef9ad22c35126df9c38d42300ae";
  };

  nativeBuildInputs = [
    asciidoc
    python
    re2c
  ];

  postPatch = ''
    patchShebangs ./configure.py
  '';

  buildPhase = ''
    runHook 'preBuild'
    ./configure.py '--bootstrap' '--verbose'
    asciidoc doc/manual.asciidoc
    runHook 'postBuild'
  '';

  installPhase = ''
    runHook 'preInstall'
    install -vD 'ninja' "$out/bin/ninja"
    install -vD 'doc/manual.asciidoc' "$out/share/doc/ninja/manual.asciidoc"
    install -vD 'doc/manual.html' "$out/share/doc/ninja/doc/manual.html"
    runHook 'postInstall'
  '';

  setupHook = ./setup-hook.sh;

  meta = with stdenv.lib; {
    description = "Small build system with a focus on speed";
    homepage = http://martine.github.io/ninja/;
    license = licenses.asl20;
    maintainers = with maintainers; [
      codyopel
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
