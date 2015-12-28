{ stdenv, fetchgit, pythonPackages, docutils
, acl, binutils, bzip2, cdrkit, cpio, diffutils, e2fsprogs, file, gettext
, gnupg, gzip, pdftk, poppler_utils, rpm, sqlite, squashfsTools, unzip, vim, xz
}:

pythonPackages.buildPythonPackage rec {
  name = "diffoscope-${version}";
  version = "44";

  namePrefix = "";

  src = fetchgit {
    url = "git://anonscm.debian.org/reproducible/diffoscope.git";
    rev = "refs/tags/${version}";
    sha256 = "1sisdmh1bl62b16yfjy9mxxdfzhskrabp0l3pl1kxn7db0c4vpac";
  };

  postPatch = ''
    # Upstream doesn't provide a PKG-INFO file
    sed -i setup.py -e "/'rpm-python',/d"
  '';

  # Still missing these tools: enjarify ghc img2txt javap otool(maybe OS X only) ppudump showttf sng
  # Also these libraries: python3-guestfs
  propagatedBuildInputs = (with pythonPackages; [ debian libarchive-c python_magic tlsh ]) ++
    [ acl binutils bzip2 cdrkit cpio diffutils e2fsprogs file gettext gnupg
      gzip pdftk poppler_utils rpm sqlite squashfsTools unzip vim xz ];

  doCheck = false; # Calls 'mknod' in squashfs tests, which needs root

  postInstall = ''
    mkdir -p $out/share/man/man1
    ${docutils}/bin/rst2man.py debian/diffoscope.1.rst $out/share/man/man1/diffoscope.1
  '';

  meta = with stdenv.lib; {
    description = "Perform in-depth comparison of files, archives, and directories";
    longDescription = ''
      diffoscope will try to get to the bottom of what makes files or directories
      different. It will recursively unpack archives of many kinds and transform
      various binary formats into more human readable form to compare them. It can
      compare two tarballs, ISO images, or PDF just as easily. The differences can
      be shown in a text or HTML report.

      diffoscope is developed as part of the "reproducible builds" Debian
      project and was formerly known as "debbindiff".
    '';
    homepage = https://wiki.debian.org/ReproducibleBuilds;
    license = licenses.gpl3Plus;
    maintainers = [ maintainers.dezgeg ];
    platforms = platforms.linux;
  };
}
