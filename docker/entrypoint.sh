#!/usr/bin/env bash
set -eux

GENERATED_BY="generated by $(realpath ${0})"
# settings defaults
: "${KMI_LOGGER_LEVEL:=INFO}"
: "${KMI_LOGGER_ROOT_LEVEL:=WARN}"

# generate config from env
cat - > 'server.ini' <<CONFIG
# ${GENERATED_BY}
[app:main]
use = egg:keas.kmi
storage-dir=keys/

[server:main]
use = egg:gunicorn#main
host = 0.0.0.0
port = 8080
worker_class = sync

# Logging Configuration
[loggers]
keys = root, kmi

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = ${KMI_LOGGER_ROOT_LEVEL}
handlers = console

[logger_kmi]
level = ${KMI_LOGGER_LEVEL}
handlers = console
propagate = 0
qualname = kmi

[handler_console]
class = StreamHandler
args = (sys.stdout,)
formatter = generic

[formatter_generic]
format = %(asctime)s %(levelname)-5.5s [%(name)s] %(message)s
datefmt= %Y-%m-%d %H:%M:%S

CONFIG

cat - > 'zope.conf' <<ZOPE
# ${GENERATED_BY}
site-definition src/keas/kmi/application.zcml

<eventlog>
  # This sets up logging to both a file and to standard output
  # (STDOUT).  The "path" setting can be a relative or absolute
  # filesystem path or the tokens STDOUT or STDERR.

  <logfile>
    path STDOUT
    formatter zope.exceptions.log.Formatter
  </logfile>
</eventlog>
ZOPE

# resume entrypoint stuff
if [[ "${1:-}" == 'run' ]]; then
    ls keys/
    exec gunicorn --paste 'server.ini'
else
    exec "$@"
fi
