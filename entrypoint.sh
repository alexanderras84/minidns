#!/bin/bash -e

# Generate webserver password if not set
if [ -z "${DNSDIST_WEBSERVER_PASSWORD}" ]; then
  echo "[INFO] Dnsdist webserver password not set - generating one"
  DNSDIST_WEBSERVER_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12)
  export DNSDIST_WEBSERVER_PASSWORD
  echo "[INFO] Generated WebServer Password: $DNSDIST_WEBSERVER_PASSWORD"
fi

# Generate webserver API key if not set
if [ -z "${DNSDIST_WEBSERVER_API_KEY}" ]; then
  echo "[INFO] Dnsdist webserver api key not set - generating one"
  DNSDIST_WEBSERVER_API_KEY=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
  export DNSDIST_WEBSERVER_API_KEY
  echo "[INFO] Generated WebServer API Key: $DNSDIST_WEBSERVER_API_KEY"
fi

echo "[INFO] Generating ACL..."

# Prepare ACL files and ensure correct permissions before generating ACL
touch /etc/dnsdist/allowedClients.acl /etc/dnsdist/allowedClients.conf
chown minidns:minidns /etc/dnsdist/allowedClients.acl /etc/dnsdist/allowedClients.conf
chmod 644 /etc/dnsdist/allowedClients.acl /etc/dnsdist/allowedClients.conf

set +e
source /generateACL.sh
set -e

echo "[INFO] Generating DNSDist Config..."
/bin/bash /etc/dnsdist/dnsdist.conf.template > /etc/dnsdist/dnsdist.conf

if [ "${DYNDNS_CRON_ENABLED:-false}" = true ]; then
  echo "[INFO] DynDNS Address in ALLOWED_CLIENTS detected => Enable cron job"
  echo "${DYNDNS_CRON_SCHEDULE:-*/1 * * * *} /bin/bash /dynDNSCron.sh" > /etc/minidns/dyndns.cron
  supercronic /etc/minidns/dyndns.cron &
fi

echo "[INFO] Starting DNSDist..."
/usr/bin/dnsdist -C /etc/dnsdist/dnsdist.conf --supervised --disable-syslog --uid minidns --gid minidns