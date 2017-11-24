import os
import fnmatch
import shutil

whitelisted_modules = [
  '__init__',
  'aggregation',
  'aliases',
  'args',
  'async',
  'atomicfile',
  'cache',
  'config',
  'core',
  'cmd_json',
  'cmd_yaml',
  'cmd_yamlex',
  'cmdmod',
  'context',
  'crypt',
  'data',
  'defaults',
  'decorators',
  'debug',
  'dicttrim',
  'dictupdate',
  'disks',
  'dns',
  'doc',
  'environ',
  'error',
  'event',
  'extra',
  'file_tree',
  'files',
  'git_pillar',
  'gitfs',
  'gzip_util',
  'hashutils',
  'http',
  'http_json',
  'http_yaml',
  'immutabletypes',
  'itertools',
  'jid',
  'jinja',
  'job',
  'kinds',
  'lazy',
  'locales',
  'log',
  'migrations',
  'minion',
  'minions',
  'nb_popen',
  'network',
  'odict',
  'openstack',
  'opts',
  'parsers',
  'pkg',
  'platform',
  'powershell',
  'print_cli',
  'process',
  'reactor',
  'rsax931',
  'salt_proxy',
  'saltclass',
  'saltcloudmod',  # ???
  'saltutil',
  'schedule',
  'selinux',
  'service',
  'smbios',
  'stack',
  'state',
  'stalekey',
  'status',
  'stringio',
  'sysfs',
  'templates',
  'test',
  'thin',
  'timed_subprocess',
  'url',
  'validate',
  'verify',
  'versions',
  'vt',
  'xdg',
  'xmlutil',
  'yamldumper',
  'yamlencoding',
  'yamlloader',
  'webhook',
  'zeromq'
]

module_dirs = [
  'salt/beacons/',
  'salt/cloud/clouds/',
  'salt/engines/',
  'salt/grains/',
  'salt/log/handlers/',
  'salt/modules/',
  ###'salt/output/',
  'salt/pillar/',
  'salt/proxy/',
  'salt/renderers/',
  'salt/returners/',
  'salt/sdb/',
  'salt/states/',
  'salt/utils/'
]

# Remove all files/directories not whitelisted in module_dirs.
for module_dir in module_dirs:
  for module in os.listdir(module_dir):
    if os.path.isfile(os.path.join(module_dir, module)):
      modulename, extension = os.path.splitext(module)
    else:
      modulename = module
    if modulename not in whitelisted_modules:
      if os.path.isdir(os.path.join(module_dir, module)):
        shutil.rmtree(os.path.join(module_dir, module))
      else:
        os.remove(os.path.join(module_dir, module))
