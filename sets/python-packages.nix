{ pkgs
, python
, self
, stdenv

, newBootstrap ? false
}:

with pkgs.lib;

let
  # DEPRECATED: Use python.<func> instead
  pythonAtLeast = python.pythonAtLeast;
  pythonOlder = python.pythonOlder;
  isPy2 = python.isPy2;
  isPy3 = python.isPy3;
  isPyPy = python.isPyPy;

  fetchPyPi = { package, version, sha256, type ? ".tar.gz" }:
    pkgs.fetchurl rec {
      name = "${package}-${version}${type}";
      url = "https://localhost/not-a-url";
      fullOpts = {
        preFetch = ''
          $curl 'https://pypi.org/pypi/${package}/json' | \
            ${pkgs.jq}/bin/jq -r '
              .releases["${version}"] |
                reduce .[] as $item ("";
                  if $item.filename == "${name}" then
                    $item.url
                  else
                    .
                  end)
            ' > "$TMPDIR/url"
          urls=($(cat "$TMPDIR/url"))
        '';
      };
      inherit sha256;
    };

  # Stage 1 pkgs, builds wheel dists
  buildBootstrapPythonPackage = makeOverridable (
    callPackage ../pkgs/b/build-python-package rec {
      stage = 1;
      namePrefix = python.libPrefix + "-stage1-";

      # Stage 0 pkgs, builds basic egg dists
      appdirs = callPackage ../pkgs/a/appdirs/bootstrap.nix { };
      packaging = callPackage ../pkgs/p/packaging/bootstrap.nix {
        inherit
          pyparsing
          six;
      };
      pip = callPackage ../pkgs/p/pip/bootstrap.nix {
        inherit
          setuptools;
      };
      pyparsing = callPackage ../pkgs/p/pyparsing/bootstrap.nix { };
      setuptools = callPackage ../pkgs/s/setuptools/bootstrap.nix {
        inherit
          appdirs
          packaging
          pyparsing
          six;
      };
      six = callPackage ../pkgs/s/six/bootstrap.nix { };
      wheel = callPackage ../pkgs/w/wheel/bootstrap.nix {
        inherit
          setuptools;
      };
    }
  );

  # Stage 2 pkgs, builds final wheel dists
  buildPythonPackage = makeOverridable (
    callPackage ../pkgs/b/build-python-package rec {
      stage = 2;
      inherit (self)
        packaging
        pip
        pyparsing
        # setuptools
        six
        wheel;
      # Upstream setuptools bug breaks namespaced packages when install to
      # a wheel dist from a wheel dist.
      # Upstream fix for installing to an egg dist from a wheel.
      # https://github.com/pypa/setuptools/commit/b9df5fd4d08347b9db0e486af43d08978cb9f4bc
      setuptools =
        if newBootstrap == true then
          self.setuptools
        else
          callPackage ../pkgs/s/setuptools/bootstrap.nix { };
    }
  );

  callPackage = pkgs.newScope (self // {
    inherit pkgs;
    pythonPackages = self;
  });

  callPackageAlias = package: newAttrs: self."${package}".override newAttrs;

in {

  inherit
    buildBootstrapPythonPackage
    buildPythonPackage
    fetchPyPi
    isPy2
    isPyPy
    isPy3
    python
    pythonAtLeast
    pythonOlder;

  # helpers

  wrapPython = pkgs.makeSetupHook {
    deps = pkgs.makeWrapper;
    substitutions.libPrefix = python.libPrefix;
    substitutions.executable = python.interpreter;
    substitutions.magicalSedExpression =
      let
        # Looks weird? Of course, it's between single quoted shell strings.
        # NOTE: Order DOES matter here, so single character quotes need to be
        #       at the last position.
        quoteVariants = [
          "'\"'''\"'"
          "\"\"\""
          "\""
          "'\"'\"'"
        ];

        mkStringSkipper =
          labelNum: quote:
          let
            label = "q${toString labelNum}";
            isSingle = elem quote [ "\"" "'\"'\"'" ];
            endQuote = if isSingle then "[^\\\\]${quote}" else quote;
          in ''
            /^ *[a-z]?${quote}/ {
              /${quote}${quote}|${quote}.*${endQuote}/{n;br}
              :${label}; n; /^${quote}/{n;br}; /${endQuote}/{n;br}; b${label}
            }
          '';
      in ''
        1 {
          /^#!/!b; :r
          /\\$/{N;br}
          /__future__|^ *(#.*)?$/{n;br}
          ${concatImapStrings mkStringSkipper quoteVariants}
          /^ *[^# ]/i import sys; sys.argv[0] = '"'$(basename "$f")'"'
        }
      '';
  } ../pkgs/b/build-python-package/wrap.sh;

  # specials

  recursivePthLoader = callPackage ../pkgs/r/recursive-pth-loader { };

################################################################################
################################################################################
################################################################################
################################################################################
################################################################################
############################### BEGIN ALL PKGS #################################
################################################################################
################################################################################
################################################################################
################################################################################
################################################################################

affinity = callPackage ../pkgs/a/affinity { };

alabaster = callPackage ../pkgs/a/alabaster { };

aniso8601 = callPackage ../pkgs/a/aniso8601 { };

ansible = callPackage ../pkgs/a/ansible { };

antlr4-python3-runtime = callPackage ../pkgs/a/antlr4-python3-runtime { };

apache-libcloud = callPackage ../pkgs/a/apache-libcloud { };

appdirs = callPackage ../pkgs/a/appdirs {
  buildPythonPackage = self.buildBootstrapPythonPackage;
};

apscheduler = callPackage ../pkgs/a/apscheduler { };

asciinema = callPackage ../pkgs/a/asciinema { };

asn1crypto = callPackage ../pkgs/a/asn1crypto { };

astroid = callPackage ../pkgs/a/astroid { };

attr = callPackage ../pkgs/p/python-attr { };

attrs = callPackage ../pkgs/a/attrs { };

automat = callPackage ../pkgs/a/automat { };

autotorrent = callPackage ../pkgs/a/autotorrent { };

aws-cli = callPackage ../pkgs/a/aws-cli { };

babel = callPackage ../pkgs/b/babel { };

babelfish = callPackage ../pkgs/b/babelfish { };

backports-ssl-match-hostname =
  callPackage ../pkgs/b/backports-ssl-match-hostname { };

bazaar = callPackage ../pkgs/b/bazaar { };

bcrypt = callPackage ../pkgs/b/bcrypt { };

beautifulsoup = callPackage ../pkgs/b/beautifulsoup { };

beets = callPackage ../pkgs/b/beets {
  channel = "stable";
};
beets_head = callPackage ../pkgs/b/beets {
  channel = "head";
};

bleach = callPackage ../pkgs/b/bleach { };

blist = callPackage ../pkgs/b/blist { };

boost_1-66 = callPackage ../pkgs/b/boost/python.nix {
  channel = "1.66";
};
boost_1-70 = callPackage ../pkgs/b/boost/python.nix {
  channel = "1.70";
};
boost = callPackageAlias "boost_1-70" { };

borgbackup = callPackage ../pkgs/b/borgbackup { };

borgmatic = callPackage ../pkgs/b/borgmatic { };

botocore = callPackage ../pkgs/b/botocore { };

brotli = callPackage ../pkgs/b/brotli/python.nix {
  brotli = pkgs.brotli;
};

bzrtools = callPackage ../pkgs/b/bzrtools { };

canonicaljson = callPackage ../pkgs/c/canonicaljson { };

#certbot = callPackage ../pkgs/c/certbot { };

certifi = callPackage ../pkgs/c/certifi { };

cffi = callPackage ../pkgs/c/cffi { };

characteristic = callPackage ../pkgs/c/characteristic { };

chardet = callPackage ../pkgs/c/chardet { };

cheetah = callPackage ../pkgs/c/cheetah { };

cheroot = callPackage ../pkgs/c/cheroot { };

cherrypy = callPackage ../pkgs/c/cherrypy { };

click = callPackage ../pkgs/c/click { };

colorama = callPackage ../pkgs/c/colorama { };

colorclass = callPackage ../pkgs/c/colorclass { };

constantly = callPackage ../pkgs/c/constantly { };

cryptography = callPackage ../pkgs/c/cryptography { };

cryptography-vectors = callPackage ../pkgs/c/cryptography-vectors { };

cvs2svn = callPackage ../pkgs/c/cvs2svn { };

cython = callPackage ../pkgs/c/cython { };

daemonize = callPackage ../pkgs/d/daemonize { };

dbus-python = callPackage ../pkgs/d/dbus-python { };

debtcollector = callPackage ../pkgs/d/debtcollector { };

decorator = callPackage ../pkgs/d/decorator { };

defusedxml = callPackage ../pkgs/d/defusedxml { };

deluge = callPackage ../pkgs/d/deluge {
  channel = "stable";
};
deluge_head = callPackage ../pkgs/d/deluge {
  channel = "head";
};

deluge-client = callPackage ../pkgs/d/deluge-client { };

diffoscope = callPackage ../pkgs/d/diffoscope { };

discogs-client = callPackage ../pkgs/d/discogs-client { };

dnsdiag = callPackage ../pkgs/d/dnsdiag { };

dnspython = callPackage ../pkgs/d/dnspython { };

docopt = callPackage ../pkgs/d/docopt { };

docutils = callPackage ../pkgs/d/docutils { };

duplicity = callPackage ../pkgs/d/duplicity { };

enum34 = callPackage ../pkgs/e/enum34 { };

etcd = callPackage ../pkgs/e/etcd-py { };

fasteners = callPackage ../pkgs/f/fasteners { };

fido2 = callPackage ../pkgs/f/fido2 { };

flask = callPackage ../pkgs/f/flask { };

flask-compress = callPackage ../pkgs/f/flask-compress { };

flask-login = callPackage ../pkgs/f/flask-login { };

flask-restful = callPackage ../pkgs/f/flask-restful { };

flask-restplus = callPackage ../pkgs/f/flask-restplus { };

flexget = callPackage ../pkgs/f/flexget { };

fonttools = callPackage ../pkgs/f/fonttools { };

foolscap = callPackage ../pkgs/f/foolscap { };

frozendict = callPackage ../pkgs/f/frozendict { };

funcsigs = callPackage ../pkgs/f/funcsigs { };

functools32 = callPackage ../pkgs/f/functools32 { };

future = callPackage ../pkgs/f/future { };

futures = callPackage ../pkgs/f/futures { };

gevent = callPackage ../pkgs/g/gevent { };

greenlet = callPackage ../pkgs/g/greenlet { };

gst-python_1-14 = callPackage ../pkgs/g/gst-python {
  channel = "1.14";
  gst-plugins-base = pkgs.gst-plugins-base_1-14;
  gstreamer = pkgs.gstreamer_1-14;
};
gst-python = callPackageAlias "gst-python_1-14" { };

guessit = callPackage ../pkgs/g/guessit { };

gyp = callPackage ../pkgs/g/gyp { };

h2 = callPackage ../pkgs/h/h2 { };

hkdf = callPackage ../pkgs/h/hkdf { };

hpack = callPackage ../pkgs/h/hpack { };

html5lib = callPackage ../pkgs/h/html5lib { };

hyperframe = callPackage ../pkgs/h/hyperframe { };

hyperlink = callPackage ../pkgs/h/hyperlink { };

idna = callPackage ../pkgs/i/idna { };

incremental = callPackage ../pkgs/i/incremental { };

iotop = callPackage ../pkgs/i/iotop { };

imagesize = callPackage ../pkgs/i/imagesize { };

ip-associations-python-novaclient-ext =
  callPackage ../pkgs/i/ip-associations-python-novaclient-ext { };

ipaddress = callPackage ../pkgs/i/ipaddress { };

iso8601 = callPackage ../pkgs/i/iso8601 { };

isort = callPackage ../pkgs/i/isort { };

itstool = callPackage ../pkgs/i/itstool { };

jaraco-classes = callPackage ../pkgs/j/jaraco-classes { };

jinja2 = callPackage ../pkgs/j/jinja2 { };

jmespath = callPackage ../pkgs/j/jmespath { };

jsonschema = callPackage ../pkgs/j/jsonschema { };

keyring = callPackage ../pkgs/k/keyring { };

keystoneauth1 = callPackage ../pkgs/k/keystoneauth1 { };

lazy-object-proxy = callPackage ../pkgs/l/lazy-object-proxy { };

ldap3 = callPackage ../pkgs/l/ldap3 { };

libarchive-c = callPackage ../pkgs/l/libarchive-c { };

libcap-ng = callPackage ../pkgs/l/libcap-ng/python.nix { };

llfuse = callPackage ../pkgs/l/llfuse { };

lockfile = callPackage ../pkgs/l/lockfile { };

lxml = callPackage ../pkgs/l/lxml { };

libxml2 = callPackage ../pkgs/l/libxml2/python.nix {
  libxml2 = pkgs.libxml2;
};

m2crypto = callPackage ../pkgs/m/m2crypto { };

m2r = callPackage ../pkgs/m/m2r { };

magic-wormhole = callPackage ../pkgs/m/magic-wormhole { };

mako = callPackage ../pkgs/m/mako { };
Mako = callPackageAlias "mako" { };  # DEPRECATED

markupsafe = callPackage ../pkgs/m/markupsafe { };

matrix-angular-sdk = callPackage ../pkgs/m/matrix-angular-sdk { };

matrix-synapse-ldap3 = callPackage ../pkgs/m/matrix-synapse-ldap3 { };

mccabe = callPackage ../pkgs/m/mccabe { };

meson = callPackage ../pkgs/m/meson { };

mercurial = callPackage ../pkgs/m/mercurial { };

mistune = callPackage ../pkgs/m/mistune { };

monotonic = callPackage ../pkgs/m/monotonic { };

mopidy = callPackage ../pkgs/m/mopidy { };

more-itertools = callPackage ../pkgs/m/more-itertools { };

mpdris2 = callPackage ../pkgs/m/mpdris2 { };

msgpack-python = callPackage ../pkgs/m/msgpack-python { };

mutagen = callPackage ../pkgs/m/mutagen { };

netaddr = callPackage ../pkgs/n/netaddr { };

netifaces = callPackage ../pkgs/n/netifaces { };

nevow = callPackage ../pkgs/n/nevow { };

oauthlib = callPackage ../pkgs/o/oauthlib { };

olefile = callPackage ../pkgs/o/olefile { };

os-diskconfig-python-novaclient-ext =
  callPackage ../pkgs/o/os-diskconfig-python-novaclient-ext { };

os-networksv2-python-novaclient-ext =
  callPackage ../pkgs/o/os-networksv2-python-novaclient-ext { };

os-virtual-interfacesv2-python-novaclient-ext =
  callPackage ../pkgs/o/os-virtual-interfacesv2-python-novaclient-ext { };

oslo-i18n = callPackage ../pkgs/o/oslo-i18n { };

oslo-serialization = callPackage ../pkgs/o/oslo-serialization { };

oslo-utils = callPackage ../pkgs/o/oslo-utils { };

packaging = callPackage ../pkgs/p/packaging {
  buildPythonPackage = self.buildBootstrapPythonPackage;
  inherit (self)
    pyparsing
    six;
};

paramiko = callPackage ../pkgs/p/paramiko { };

paste = callPackage ../pkgs/p/paste { };

path-py = callPackage ../pkgs/p/path-py { };
# Deprecated alias
pathpy = callPackageAlias "path-py" { };

pathlib2 = callPackage ../pkgs/p/pathlib2 { };

pbr = callPackage ../pkgs/p/pbr { };

phonenumbers = callPackage ../pkgs/p/phonenumbers { };

pillow = callPackage ../pkgs/p/pillow { };

pip = callPackage ../pkgs/p/pip {
  buildPythonPackage = self.buildBootstrapPythonPackage;
};

ply = callPackage ../pkgs/p/ply { };

portend = callPackage ../pkgs/p/portend { };

prettytable = callPackage ../pkgs/p/prettytable { };

priority = callPackage ../pkgs/p/priority { };

progressbar = callPackage ../pkgs/p/progressbar { };

psutil = callPackage ../pkgs/p/psutil { };

py = callPackage ../pkgs/p/py { };

py-bcrypt = callPackage ../pkgs/p/py-bcrypt { };

py-cpuinfo = callPackage ../pkgs/p/py-cpuinfo { };

py-lua-parser = callPackage ../pkgs/p/py-lua-parser { };

py-lua-style = callPackage ../pkgs/p/py-lua-style { };

pyacoustid = callPackage ../pkgs/p/pyacoustid { };

pyasn1 = callPackage ../pkgs/p/pyasn1 { };

pyasn1-modules = callPackage ../pkgs/p/pyasn1-modules { };

pycairo = callPackage ../pkgs/p/pycairo { };

pycountry = callPackage ../pkgs/p/pycountry { };

pycparser = callPackage ../pkgs/p/pycparser { };

pycrypto = callPackage ../pkgs/p/pycrypto { };

pycryptodomex = callPackage ../pkgs/p/pycryptodomex { };

pycryptopp = callPackage ../pkgs/p/pycryptopp { };

pydenticon = callPackage ../pkgs/p/pydenticon { };

#pygame = callPackage ../pkgs/p/pygame { };

pygments = callPackage ../pkgs/p/pygments { };

pygobject_2 = callPackage ../pkgs/p/pygobject {
  channel = "2.28";
};
pygobject_3-30 = callPackage ../pkgs/p/pygobject/meson.nix {
  channel = "3.30";
};
pygobject = callPackageAlias "pygobject_3-30" { };
pygobject_nocairo = callPackageAlias "pygobject_3-30" {
  nocairo = true;
};

pygtk = callPackage ../pkgs/p/pygtk { };

pyhamcrest = callPackage ../pkgs/p/pyhamcrest { };

pykka = callPackage ../pkgs/p/pykka { };

pykwalify = callPackage ../pkgs/p/pykwalify { };

pylast = callPackage ../pkgs/p/pylast { };

pylint = callPackage ../pkgs/p/pylint { };

pymacaroons-pynacl = callPackage ../pkgs/p/pymacaroons-pynacl { };

pymysql = callPackage ../pkgs/p/pymysql { };

pynacl = callPackage ../pkgs/p/pynacl { };

pynzb = callPackage ../pkgs/p/pynzb { };

pyodbc = callPackage ../pkgs/p/pyodbc { };

pyopenssl = callPackage ../pkgs/p/pyopenssl { };

pyparsing = callPackage ../pkgs/p/pyparsing {
  buildPythonPackage = self.buildBootstrapPythonPackage;
};

pyrax = callPackage ../pkgs/p/pyrax { };

pyrss2gen = callPackage ../pkgs/p/pyrss2gen { };

pysaml2 = callPackage ../pkgs/p/pysaml2 { };

pyscard = callPackage ../pkgs/p/pyscard { };

pyserial = callPackage ../pkgs/p/pyserial { };

pytest = callPackage ../pkgs/p/pytest { };

pytest-benchmark = callPackage ../pkgs/p/pytest-benchmark { };

pytest-capturelog = callPackage ../pkgs/p/pytest-capturelog { };

pytest-runner = callPackage ../pkgs/p/pytest-runner { };

python-dateutil = callPackage ../pkgs/p/python-dateutil { };

python-etcd = callPackage ../pkgs/p/python-etcd { };

python-ldap = callPackage ../pkgs/p/python-ldap { };

python-magic = callPackage ../pkgs/p/python-magic { };

python-mpd2 = callPackage ../pkgs/p/python-mpd2 { };

python-novaclient = callPackage ../pkgs/p/python-novaclient { };

python-tvrage = callPackage ../pkgs/p/python-tvrage { };

pytz = callPackage ../pkgs/p/pytz { };

pyudev = callPackage ../pkgs/p/pyudev { };

pyusb = callPackage ../pkgs/p/pyusb { };

pyutil = callPackage ../pkgs/p/pyutil { };

pywbem = callPackage ../pkgs/p/pywbem { };

pyyaml = callPackage ../pkgs/p/pyyaml { };

pyzmq = callPackage ../pkgs/p/pyzmq { };

rackspace-auth-openstack =
  callPackage ../pkgs/r/rackspace-auth-openstack { };

rackspace-novaclient = callPackage ../pkgs/r/rackspace-novaclient { };

rarfile = callPackage ../pkgs/r/rarfile { };

rax-default-network-flags-python-novaclient-ext =
  callPackage ../pkgs/r/rax-default-network-flags-python-novaclient-ext { };

rax-scheduled-images-python-novaclient-ext =
  callPackage ../pkgs/r/rax-scheduled-images-python-novaclient-ext { };

rebulk = callPackage ../pkgs/r/rebulk { };

regex = callPackage ../pkgs/r/regex { };

rencode = callPackage ../pkgs/r/rencode { };

repoze-who = callPackage ../pkgs/r/repoze-who { };

requests = callPackage ../pkgs/r/requests { };

requests-toolbelt = callPackage ../pkgs/r/requests-toolbelt { };

rpyc = callPackage ../pkgs/r/rpyc { };

rsa = callPackage ../pkgs/r/rsa { };

ruamel-yaml = callPackage ../pkgs/r/ruamel-yaml { };

s3transfer = callPackage ../pkgs/s/s3transfer { };

safe = callPackage ../pkgs/s/safe { };

salt_2016-11 = callPackage ../pkgs/s/salt {
  channel = "2016.11";
};
salt_2017-7 = callPackage ../pkgs/s/salt {
  channel = "2017.7";
};
salt_head = callPackage ../pkgs/s/salt {
  channel = "head";
};
salt = callPackageAlias "salt_2016-11" { };

scandir = callPackage ../pkgs/s/scandir { };

scons = callPackage ../pkgs/s/scons { };

secretstorage = callPackage ../pkgs/s/secretstorage { };

service-identity = callPackage ../pkgs/s/service-identity { };

setproctitle = callPackage ../pkgs/s/setproctitle { };

setuptools = callPackage ../pkgs/s/setuptools {
  buildPythonPackage = self.buildBootstrapPythonPackage;
  inherit (self)
    appdirs
    packaging
    pyparsing
    six;
};

setuptools-scm = callPackage ../pkgs/s/setuptools-scm { };

setuptools-trial = callPackage ../pkgs/s/setuptools-trial { };

signedjson = callPackage ../pkgs/s/signedjson { };

simplejson = callPackage ../pkgs/s/simplejson { };

six = callPackage ../pkgs/s/six {
  buildPythonPackage = self.buildBootstrapPythonPackage;
};

slimit = callPackage ../pkgs/s/slimit { };

snowballstemmer = callPackage ../pkgs/s/snowballstemmer { };

spake2 = callPackage ../pkgs/s/spake2 { };

speedtest-cli = callPackage ../pkgs/s/speedtest-cli { };

sphinx = callPackage ../pkgs/s/sphinx { };

sphinxcontrib-websupport =
  callPackage ../pkgs/s/sphinxcontrib-websupport { };

sqlalchemy = callPackage ../pkgs/s/sqlalchemy { };

stevedore = callPackage ../pkgs/s/stevedore { };

sydent = callPackage ../pkgs/s/sydent { };

synapse = callPackage ../pkgs/s/synapse { };

tahoe-lafs = callPackage ../pkgs/t/tahoe-lafs { };

tempora = callPackage ../pkgs/t/tempora { };

terminaltables = callPackage ../pkgs/t/terminaltables { };

tmdb3 = callPackage ../pkgs/t/tmdb3 { };

tornado = callPackage ../pkgs/t/tornado { };

transmission-remote-gnome =
  callPackage ../pkgs/t/transmission-remote-gnome { };

transmissionrpc = callPackage ../pkgs/t/transmissionrpc { };

twisted = callPackage ../pkgs/t/twisted { };

typed-ast = callPackage ../pkgs/t/typed-ast { };

typing = callPackage ../pkgs/t/typing { };

tzlocal = callPackage ../pkgs/t/tzlocal { };

ujson = callPackage ../pkgs/u/ujson { };

unidecode = callPackage ../pkgs/u/unidecode { };

unpaddedbase64 = callPackage ../pkgs/u/unpaddedbase64 { };

urllib3 = callPackage ../pkgs/u/urllib3 { };

vapoursynth = callPackage ../pkgs/v/vapoursynth { };
vapoursynth_head = callPackage ../pkgs/v/vapoursynth {
  channel = "head";
};

vcversioner = callPackage ../pkgs/v/vcversioner { };

waf = callPackage ../pkgs/w/waf { };

webencodings = callPackage ../pkgs/w/webencodings { };

webob = callPackage ../pkgs/w/webob { };

werkzeug = callPackage ../pkgs/w/werkzeug { };

wheel = callPackage ../pkgs/w/wheel {
  buildPythonPackage = self.buildBootstrapPythonPackage;
};

wrapt = callPackage ../pkgs/w/wrapt { };

xcb-proto = callPackage ../pkgs/x/xcb-proto { };

yapf = callPackage ../pkgs/y/yapf { };

youtube-dl = callPackage ../pkgs/y/youtube-dl { };

yubikey-manager = callPackage ../pkgs/y/yubikey-manager { };

zbase32 = callPackage ../pkgs/z/zbase32 { };

zc-lockfile = callPackage ../pkgs/z/zc-lockfile { };

zfec = callPackage ../pkgs/z/zfec { };

zope-component = callPackage ../pkgs/z/zope-component { };

zope-event = callPackage ../pkgs/z/zope-event { };

zope-interface = callPackage ../pkgs/z/zope-interface { };

zxcvbn-python = callPackage ../pkgs/z/zxcvbn-python { };

################################################################################
################################################################################
################################################################################
################################################################################
################################################################################
################################ END ALL PKGS ##################################
################################################################################
################################################################################
################################################################################
################################################################################
################################################################################

  # acme = buildPythonPackage rec {
  #   inherit (self.certbot) src version;
  #   name = "acme-${version}";
  #   srcRoot = "certbot-v${version}/acme";
  #
  #   propagatedBuildInputs = with self; [
  #     cryptography
  #     mock
  #     ndg-httpsclient
  #     pyasn1
  #     pyopenssl
  #     pytz
  #     requests
  #     pyRFC3339
  #   ];
  #
  #   disabled = isPy3;
  # };

   audioread = buildPythonPackage rec {
     name = "audioread-${version}";
     version = "2.1.5";

     src = fetchPyPi {
       package = "audioread";
       inherit version;
       sha256 = "36c3b118f097c58ba073b7d040c4319eff200756f094295677567e256282d0d7";
     };

     # No tests, need to disable or py3k breaks

     meta = {
       description = "Cross-platform audio decoding";
       homepage = "https://github.com/sampsyo/audioread";
       license = licenses.mit;
     };
   };

   responses = self.buildPythonPackage rec {
     name = "responses-${version}";
     version = "0.9.0";

     src = fetchPyPi {
       package = "responses";
       inherit version;
       sha256 = "c6082710f4abfb60793899ca5f21e7ceb25aabf321560cc0726f8b59006811c9";
     };

     propagatedBuildInputs = with self; [
        cookies
        mock
        requests
        six
     ];
   };

   pyechonest = self.buildPythonPackage rec {
     name = "pyechonest-9.0.0";

     src = pkgs.fetchurl {
       url = "https://pypi.python.org/packages/source/p/pyechonest/${name}.tar.gz";
       fullOpts = {
         md5Confirm = "c633dce658412e3ec553efd25d7d2686";
       };
       sha256 = "1584nira3rkiman9dm81kdshihmkj21s8navndz2l8spnjwb790x";
     };

     meta = {
       description = "Tap into The Echo Nest's Musical Brain for the best music search, information, recommendations and remix tools on the web";
       homepage = https://github.com/echonest/pyechonest;
     };
   };

   blinker = buildPythonPackage rec {
     name = "blinker-${version}";
     version = "1.4";

     src = pkgs.fetchurl {
       url = "https://pypi.python.org/packages/source/b/blinker/${name}.tar.gz";
       fullOpts = {
         md5Confirm = "8b3722381f83c2813c52de3016b68d33";
       };
       sha256 = "1dpq0vb01p36jjwbhhd08ylvrnyvcc82yxx3mwjx6awrycjyw6j7";
     };

     meta = {
       homepage = http://pythonhosted.org/blinker/;
       description = "Fast, simple object-to-object and broadcast signaling";
       license = licenses.mit;
       maintainers = with maintainers; [ ];
     };
   };

   configobj = buildPythonPackage rec {
     name = "configobj-5.0.6";

     src = pkgs.fetchurl {
       url = "https://pypi.python.org/packages/source/c/configobj/${name}.tar.gz";
       sha256 = "a2f5650770e1c87fb335af19a9b7eb73fc05ccf22144eb68db7d00cd2bcb0902";
     };

     buildInputs = with self; [
       six
     ];

     # error: invalid command 'test'
   };

   cookies = buildPythonPackage rec {
     name = "cookies-2.2.1";

     src = pkgs.fetchurl {
       url = "https://pypi.python.org/packages/source/c/cookies/${name}.tar.gz";
       sha256 = "13pfndz8vbk4p2a44cfbjsypjarkrall71pgc97glk5fiiw9idnn";
     };


     meta = {
       description = "Friendlier RFC 6265-compliant cookie parser/renderer";
       homepage = https://github.com/sashahart/cookies;
       license = licenses.mit;
     };
   };

   coverage = buildPythonPackage rec {
     name = "coverage-${version}";
     version = "4.5.1";

     src = fetchPyPi {
       package = "coverage";
       inherit version;
       sha256 = "56e448f051a201c5ebbaa86a5efd0ca90d327204d8b059ab25ad0f35fbfd79f1";
     };
   };

   cov-core = buildPythonPackage rec {
     name = "cov-core-${version}";
     version = "1.15.0";

     src = fetchPyPi {
       package = "cov-core";
       inherit version;
       sha256 = "4a14c67d520fda9d42b0da6134638578caae1d374b9bb462d8de00587dba764c";
     };

     propagatedBuildInputs = with self; [
        coverage
     ];
    };

   pytestcov = buildPythonPackage (rec {
     name = "pytest-cov-${version}";
     version = "2.5.1";

     src = fetchPyPi {
       package = "pytest-cov";
       inherit version;
       sha256 = "03aa752cf11db41d281ea1d807d954c4eda35cfa1b21d6971966cc041bbf6e2d";
     };

    buildInputs = with self; [ cov-core pytest ];

     meta = {
       description = "plugin for coverage reporting with support for both centralised and distributed testing, including subprocesses and multiprocessing";
       homepage = https://github.com/schlamar/pytest-cov;
       license = licenses.mit;
     };
   });

   itsdangerous = buildPythonPackage rec {
     name = "itsdangerous-0.24";

     src = pkgs.fetchurl {
       url = "https://pypi.python.org/packages/source/i/itsdangerous/${name}.tar.gz";
       sha256 = "06856q6x675ly542ig0plbqcyab6ksfzijlyf1hzhgg3sgwgrcyb";
     };
   };

   ndg-httpsclient = buildPythonPackage rec {
     name = "ndg-httpsclient-${version}";
     version = "0.4.2";

     src = fetchPyPi {
       package = "ndg_httpsclient";
       inherit version;
       sha256 = "580987ef194334c50389e0d7de885fccf15605c13c6eecaabd8d6c43768eb8ac";
     };

     buildInputs = with self; [
       pyopenssl
     ];
   };

   pyxdg = buildPythonPackage rec {
     name = "pyxdg-0.25";

     src = pkgs.fetchurl {
       url = "https://pypi.python.org/packages/source/p/pyxdg/${name}.tar.gz";
       fullOpts = {
         md5Confirm = "bedcdb3a0ed85986d40044c87f23477c";
       };
       sha256 = "179767h8m634ydlm4v8lnz01ba42gckfp684id764zaip7h87s41";
     };

     # error: invalid command 'test'

     meta = {
       homepage = http://freedesktop.org/wiki/Software/pyxdg;
       description = "Contains implementations of freedesktop.org standards";
       license = licenses.lgpl2;
       maintainers = with maintainers; [ iElectric ];
     };
   };

   keepalive = buildPythonPackage rec {
     name = "keepalive-${version}";
     version = "0.5";

     src = pkgs.fetchurl {
       url = "https://pypi.python.org/packages/source/k/keepalive/keepalive-${version}.tar.gz";
       sha256 = "3c6b96f9062a5a76022f0c9d41e9ef5552d80b1cadd4fccc1bf8f183ba1d1ec1";
     };

     # No tests included

     meta = with stdenv.lib; {
       description = "An HTTP handler for `urllib2` that supports HTTP 1.1 and keepalive.";
       homepage = "https://github.com/wikier/keepalive";
     };
   };


   SPARQLWrapper = buildPythonPackage rec {
     name = "SPARQLWrapper-${version}";
     version = "1.8.0";

     src = fetchPyPi {
       package = "SPARQLWrapper";
       inherit version;
       sha256 = "3b46d0f18ca0b65b8b965d6d1ae257b229388400b06e7dc19f0a51614dc1abde";
     };

     # break circular dependency loop
     patchPhase = ''
       sed -i '/rdflib/d' requirements.txt
     '';

     propagatedBuildInputs = with self; [
       six isodate pyparsing html5lib keepalive
     ];

     meta = with stdenv.lib; {
       description = "This is a wrapper around a SPARQL service. It helps in creating the query URI and, possibly, convert the result into a more manageable format.";
       homepage = "http://rdflib.github.io/sparqlwrapper";
     };
   };

   ecdsa = buildPythonPackage rec {
     name = "ecdsa-${version}";
     version = "0.13";

     src = pkgs.fetchurl {
       url = "https://pypi.python.org/packages/source/e/ecdsa/${name}.tar.gz";
       sha256 = "1yj31j0asmrx4an9xvsaj2icdmzy6pw0glfpqrrkrphwdpi1xkv4";
     };

     # Only needed for tests
     buildInputs = with self; [ pkgs.openssl ];

     meta = {
       description = "ECDSA cryptographic signature library";
       homepage = "https://github.com/warner/python-ecdsa";
       license = licenses.mit;
       maintainers = with maintainers; [ aszlig ];
     };
   };

   feedparser = buildPythonPackage (rec {
     name = "feedparser-5.2.1";

     src = pkgs.fetchurl {
       url = "https://pypi.python.org/packages/source/f/feedparser/${name}.tar.gz";
       sha256 = "1ycva69bqssalhqg45rbrfipz3l6hmycszy26k0351fhq990c0xx";
     };

     # lots of networking failures

     meta = {
       homepage = http://code.google.com/p/feedparser/;
       description = "Universal feed parser";
       license = licenses.bsd2;
       maintainers = with maintainers; [ iElectric ];
     };
   });

   flask-cors = buildPythonPackage rec {
     name = "Flask-Cors-${version}";
     version = "3.0.2";

     src = fetchPyPi {
       package = "Flask-Cors";
       inherit version;
       sha256 = "0a09f3559ded4759387dfa2a355de59bc161f67269a1f4b7b0712a64b1f7dad6";
     };
    buildInputs = with self; [ nose ];
     propagatedBuildInputs = with self; [ flask six ];

     meta = {
       description = "A Flask extension adding a decorator for CORS support";
       homepage = https://github.com/corydolphin/flask-cors;
      license = with licenses; [ mit ];
     };
   };

   python2-pythondialog = buildPythonPackage rec {
     name = "python2-pythondialog-${version}";
     version = "3.4.0";
     disabled = !isPy2;

     src = fetchPyPi {
       package = "python2-pythondialog";
       inherit version;
       sha256 = "a96d9cea9a371b5002b5575d1ec351233112519268d382ba6f3582323b3d1335";
     };

     patchPhase = ''
       substituteInPlace dialog.py ":/bin:/usr/bin" ":$out/bin"
     '';

     meta = with stdenv.lib; {
       homepage = "http://pythondialog.sourceforge.net/";
     };
   };

   pyRFC3339 = buildPythonPackage rec {
     name = "pyRFC3339-1.0";

     src = pkgs.fetchurl {
       url = "https://pypi.python.org/packages/source/p/pyRFC3339/${name}.tar.gz";
       sha256 = "8dfbc6c458b8daba1c0f3620a8c78008b323a268b27b7359e92a4ae41325f535";
     };

     buildInputs = with self; [
       pytz
     ];

   };

   jellyfish = buildPythonPackage rec {
     version = "0.5.6";
     name = "jellyfish-${version}";

     src = fetchPyPi {
       package = "jellyfish";
       inherit version;
       sha256 = "887a9a49d0caee913a883c3e7eb185f6260ebe2137562365be422d1316bd39c9";
     };

     buildInputs = with self; [
       pytest
       unicodecsv
     ];


     meta = {
       homepage = http://github.com/sunlightlabs/jellyfish;
       description = "Approximate and phonetic matching of strings";
       maintainers = with maintainers; [ ];
     };
   };

   mock = buildPythonPackage rec {
     name = "mock-2.0.0";

     src = pkgs.fetchurl {
       url = "https://pypi.python.org/packages/source/m/mock/${name}.tar.gz";
       sha256 = "b158b6df76edd239b8208d481dc46b6afd45a846b7812ff0ce58971cf5bc8bba";
     };

     propagatedBuildInputs = with self; [
       funcsigs
       pbr
       six
     ];

   };

   munkres = buildPythonPackage rec {
     name = "munkres-${version}";
     version = "1.0.10";

     src = fetchPyPi {
       package = "munkres";
       inherit version;
       sha256 = "eb41e68e93be08ad8cb80fd470f8282f21cd2bac87b07da645e27cf9c6b014db";
     };

     # error: invalid command 'test'

     meta = {
       homepage = http://bmc.github.com/munkres/;
       description = "Munkres algorithm for the Assignment Problem";
       license = licenses.bsd3;
       maintainers = with maintainers; [ ];
     };
   };


   musicbrainzngs = buildPythonPackage rec {
     name = "musicbrainzngs-${version}";
     version = "0.6";

     src = fetchPyPi {
       package = "musicbrainzngs";
       inherit version;
       sha256 = "28ef261a421dffde0a25281dab1ab214e1b407eec568cd05a53e73256f56adb5";
     };

     meta = {
       homepage = http://alastair/python-musicbrainz-ngs;
       description = "Python bindings for musicbrainz NGS webservice";
       license = licenses.bsd2;
       maintainers = with maintainers; [ ];
     };
   };

   nose = buildPythonPackage rec {
     name = "nose-1.3.7";

     src = pkgs.fetchurl {
       url = "https://pypi.python.org/packages/source/n/nose/${name}.tar.gz";
       sha256 = "f1bffef9cbc82628f6e7d7b40d7e255aefaa1adb6a1b1d26c69a8b79e6208a98";
     };
   };

   parsedatetime = buildPythonPackage rec {
     name = "parsedatetime-${version}";
     version = "2.4";

     src = fetchPyPi {
       package = "parsedatetime";
       inherit version;
       sha256 = "3d817c58fb9570d1eec1dd46fa9448cd644eeed4fb612684b02dfda3a79cb84b";
     };

     propagatedBuildInputs = [
      self.future
     ];
   };

   fixtures = buildPythonPackage rec {
     name = "fixtures-${version}";
     version = "3.0.0";

     src = fetchPyPi {
       package = "fixtures";
       inherit version;
       sha256 = "fcf0d60234f1544da717a9738325812de1f42c2fa085e2d9252d8fff5712b2ef";
     };

     buildInputs = with self; [ pbr testtools_1 mock ];

     meta = {
       description = "Reusable state for writing clean tests and more";
       homepage = "https://pypi.python.org/pypi/fixtures";
       license = licenses.asl20;
     };
   };

   plumbum = buildPythonPackage rec {
     name = "plumbum-${version}";
     version = "1.6.3";

     buildInputs = with self; [ self.six ];

     src = fetchPyPi {
       package = "plumbum";
       inherit version;
       sha256 = "0249e708459f1b05627a7ca8787622c234e4db495a532acbbd1f1f17f28c7320";
     };
   };

   pycurl = buildPythonPackage (rec {
     name = "pycurl-${version}";
     version = "7.43.0.1";
     disabled = isPyPy; # https://github.com/pycurl/pycurl/issues/208

     src = fetchPyPi {
       package = "pycurl";
       inherit version;
       sha256 = "43231bf2bafde923a6d9bb79e2407342a5f3382c1ef0a3b2e491c6a4e50b91aa";
     };

     propagatedBuildInputs = with self; [ pkgs.curl pkgs.openssl ];

     # error: invalid command 'test'

     preConfigure = ''
       substituteInPlace setup.py --replace '--static-libs' '--libs'
       export PYCURL_SSL_LIBRARY=openssl
     '';

     meta = {
       homepage = http://pycurl.io/;
       description = "Python wrapper for libcurl";
       platforms = platforms.linux;
     };
   });

   pyjwt = buildPythonPackage rec {
     version = "1.5.2";
     name = "pyjwt-${version}";

     src = fetchPyPi {
       package = "PyJWT";
       inherit version;
       sha256 = "1179f0bff86463b5308ee5f7aff1c350e1f38139d62a723e16fb2c557d1c795f";
     };

     propagatedBuildInputs = with self; [ pycrypto ecdsa pytest-runner ];


     meta = {
       description = "JSON Web Token implementation in Python";
       homepage = https://github.com/jpadilla/pyjwt;
       license = licenses.mit;
       maintainers = with maintainers; [ ];
       platforms = platforms.linux;
     };
   };

   pymongo = buildPythonPackage rec {
     name = "pymongo-${version}";
     version = "3.5.1";

     src = fetchPyPi {
       package = "pymongo";
       inherit version;
       sha256 = "e820d93414f3bec1fa456c84afbd4af1b43ff41366321619db74e6bc065d6924";
     };


     meta = {
       homepage = "http://github.com/mongodb/mongo-python-driver";
       license = licenses.asl20;
       description = "Python driver for MongoDB ";
     };
   };

   rdflib = buildPythonPackage (rec {
     name = "rdflib-${version}";
     version = "4.2.2";

     src = fetchPyPi {
       package = "rdflib";
       inherit version;
       sha256 = "da1df14552555c5c7715d8ce71c08f404c988c58a1ecd38552d0da4fc261280d";
     };

     # error: invalid command 'test'

     propagatedBuildInputs = with self; [ isodate html5lib SPARQLWrapper ];

     meta = {
       description = "A Python library for working with RDF, a simple yet powerful language for representing information";
       homepage = http://www.rdflib.net/;
     };
   });

   isodate = buildPythonPackage rec {
     name = "isodate-${version}";
     version = "0.5.4";

     src = pkgs.fetchurl {
       url = "https://pypi.python.org/packages/source/i/isodate/${name}.tar.gz";
       sha256 = "42105c41d037246dc1987e36d96f3752ffd5c0c24834dd12e4fdbe1e79544e31";
     };

     meta = {
       description = "ISO 8601 date/time parser";
       homepage = http://cheeseshop.python.org/pypi/isodate;
     };
   };

   testscenarios = buildPythonPackage rec {
     name = "testscenarios-${version}";
     version = "0.5.0";

     src = fetchPyPi {
       package = "testscenarios";
       inherit version;
       sha256 = "c257cb6b90ea7e6f8fef3158121d430543412c9a87df30b5dde6ec8b9b57a2b6";
     };

     propagatedBuildInputs = with self; [ testtools ];

     meta = {
       description = "a pyunit extension for dependency injection";
       homepage = https://pypi.python.org/pypi/testscenarios;
       license = licenses.asl20;
     };
   };

  pyrsistent = buildPythonPackage rec {
    name = "pyrsistent-${version}";
    version = "0.12.3";

    src = fetchPyPi {
      package = "pyrsistent";
      inherit version;
      sha256 = "0614ad17af8a65d79b2550261c00686c241cea7278bf7a7fddfc7eed3f854068";
    };

    propagatedBuildInputs = with self; [
      six
    ];
  };

   testtools_1 = buildPythonPackage rec {
     name = "testtools-${version}";
     version = "1.9.0";

     src = fetchPyPi {
       package = "testtools";
       inherit version;
       sha256 = "b46eec2ad3da6e83d53f2b0eca9a8debb687b4f71343a074f83a16bbdb3c0644";
     };

     propagatedBuildInputs = with self; [
      extras
      pyrsistent
      pbr python_mimeparse extras lxml unittest2
    ];
     buildInputs = with self; [ traceback2 ];

     meta = {
       description = "A set of extensions to the Python standard library's unit testing framework";
       homepage = https://pypi.python.org/pypi/testtools;
       license = licenses.mit;
    };
   };

   testtools = buildPythonPackage rec {
     name = "testtools-${version}";
     version = "2.3.0";

     src = fetchPyPi {
       package = "testtools";
       inherit version;
       sha256 = "5827ec6cf8233e0f29f51025addd713ca010061204fdea77484a2934690a0559";
     };

     propagatedBuildInputs = with self; [
      extras
      fixtures
      pbr python_mimeparse extras lxml unittest2
    ];
     buildInputs = with self; [ traceback2 ];

     meta = {
       description = "A set of extensions to the Python standard library's unit testing framework";
       homepage = https://pypi.python.org/pypi/testtools;
       license = licenses.mit;
    };
   };

   python_mimeparse = buildPythonPackage rec {
     name = "python-mimeparse-${version}";
     version = "1.6.0";

     src = fetchPyPi {
       package = "python-mimeparse";
       inherit version;
       sha256 = "76e4b03d700a641fd7761d3cd4fdbbdcd787eade1ebfac43f877016328334f78";
     };

     # error: invalid command 'test'

     meta = {
       description = "A module provides basic functions for parsing mime-type names and matching them against a list of media-ranges";
       homepage = https://code.google.com/p/mimeparse/;
       license = licenses.mit;
     };
   };


   extras = buildPythonPackage rec {
     name = "extras-${version}";
     version = "1.0.0";

     src = fetchPyPi {
       package = "extras";
       inherit version;
       sha256 = "132e36de10b9c91d5d4cc620160a476e0468a88f16c9431817a6729611a81b4e";
     };

     # error: invalid command 'test'

     meta = {
       description = "A module provides basic functions for parsing mime-type names and matching them against a list of media-ranges";
       homepage = https://code.google.com/p/mimeparse/;
       license = licenses.mit;
     };
   };

   unicodecsv = buildPythonPackage rec {
     version = "0.14.1";
     name = "unicodecsv-${version}";

     src = pkgs.fetchurl {
       url = "https://pypi.python.org/packages/source/u/unicodecsv/${name}.tar.gz";
       sha256 = "1z7pdwkr6lpsa7xbyvaly7pq3akflbnz8gq62829lr28gl1hi301";
     };

     # ImportError: No module named runtests

     meta = {
       description = "Drop-in replacement for Python2's stdlib csv module, with unicode support";
       homepage = https://github.com/jdunck/python-unicodecsv;
       maintainers = with maintainers; [ koral ];
     };
   };

   # DEPRECATED: required by testtools, remove this package if the dependency is dropped
   unittest2 = buildPythonPackage rec {
     version = "1.1.0";
     name = "unittest2-${version}";

     src = pkgs.fetchurl {
       url = "https://pypi.python.org/packages/source/u/unittest2/unittest2-${version}.tar.gz";
       sha256 = "0y855kmx7a8rnf81d3lh5lyxai1908xjp0laf4glwa4c8472m212";
     };

     # # 1.0.0 and up create a circle dependency with traceback2/pbr

     postPatch = ''
       # # fixes a transient error when collecting tests, see https://bugs.launchpad.net/python-neutronclient/+bug/1508547
       sed -i '510i\        return None, False' unittest2/loader.py
       # https://github.com/pypa/packaging/pull/36
       sed -i 's/version=VERSION/version=str(VERSION)/' setup.py
     '' + /* argparse is part of the standard library */ ''
       sed -i setup.py \
        -e "s/'argparse',//"
     '';

     propagatedBuildInputs = with self; [ six traceback2 ];

     meta = {
       description = "A backport of the new features added to the unittest testing framework";
       homepage = https://pypi.python.org/pypi/unittest2;
     };
   };

   traceback2 = buildPythonPackage rec {
     version = "1.4.0";
     name = "traceback2-${version}";

     src = pkgs.fetchurl {
       url = "https://pypi.python.org/packages/source/t/traceback2/traceback2-${version}.tar.gz";
       sha256 = "0c1h3jas1jp1fdbn9z2mrgn3jj0hw1x3yhnkxp7jw34q15xcdb05";
     };

     propagatedBuildInputs = with self; [ pbr linecache2 ];
     # circular dependencies for tests

     meta = {
       description = "A backport of traceback to older supported Pythons.";
       homepage = https://pypi.python.org/pypi/traceback2/;
     };
   };

   linecache2 = buildPythonPackage rec {
     name = "linecache2-${version}";
     version = "1.0.0";

     src = pkgs.fetchurl {
       url = "https://pypi.python.org/packages/source/l/linecache2/${name}.tar.gz";
       sha256 = "0z79g3ds5wk2lvnqw0y2jpakjf32h95bd9zmnvp7dnqhf57gy9jb";
     };

     buildInputs = with self; [ pbr ];
     # circular dependencies for tests

     meta = with stdenv.lib; {
       description = "A backport of linecachetestscenarios to older supported Pythons.";
       homepage = "https://github.com/testing-cabal/linecache2";
     };
   };

}
