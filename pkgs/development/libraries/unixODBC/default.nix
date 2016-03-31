{ stdenv
, fetchurl

, ncurses
, readline
}:

stdenv.mkDerivation rec {
  name = "unixODBC-2.3.4";

  src = fetchurl rec {
    url = "ftp://ftp.unixodbc.org/pub/unixODBC/${name}.tar.gz";
    md5Url = "${url}.md5";
    sha256 = "2e1509a96bb18d248bf08ead0d74804957304ff7c6f8b2e5965309c632421e39";
  };

  buildInputs = [
    ncurses
    readline
  ];

  configureFlags = [
    "--disable-gui"
    "--sysconfdir=/etc"
    "--localstatedir=/var"
  ];

  meta = with stdenv.lib; {
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
