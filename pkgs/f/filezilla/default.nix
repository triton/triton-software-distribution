{ stdenv
, fetchurl
, gettext

, dbus
, gnutls
, libfilezilla
, nettle
, pugixml
, sqlite
, wxGTK
, xdg-utils
}:

let
  version = "3.27.1";

  file = "FileZilla_${version}_src.tar.bz2";
in
stdenv.mkDerivation rec {
  name = "filezilla-${version}";

  src = fetchurl {
    url = "mirror://sourceforge/filezilla/FileZilla_Client/${version}/${file}";
    sha256 = "4389fa81b62b7c816674a01f030592e44f2d8d5423f2cbcca4c7bb7417bd9a92";
  };

  nativeBuildInputs = [
    gettext
  ];

  buildInputs = [
    dbus
    gnutls
    libfilezilla
    nettle
    pugixml
    sqlite
    wxGTK
    xdg-utils
  ];

  # Allow newer wxGTK
  postPatch = ''
    awk -i inplace '
      {
        if (/if.*WX_VERSION.*3.1/) {
          dontPrint = 1;
        }
        if (!dontPrint) {
          print $0;
        }
        if (/fi/) {
          dontPrint = 0;
        }
      }
    ' configure
  '';

  configureFlags = [
    "--disable-manualupdatecheck"
  ];

  meta = with stdenv.lib; {
    description = "Graphical FTP, FTPS and SFTP client";
    homepage = http://filezilla-project.org/;
    license = licenses.gpl2;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
