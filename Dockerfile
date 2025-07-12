FROM alpine:3.20
ARG TARGETPLATFORM

# ---------- Environment Variables ----------
ENV DNSDIST_BIND_IP=0.0.0.0
ENV ALLOWED_CLIENTS=127.0.0.1
ENV ALLOWED_CLIENTS_FILE=

ENV DNSDIST_WEBSERVER_PASSWORD=
ENV DNSDIST_WEBSERVER_API_KEY=
ENV DNSDIST_WEBSERVER_NETWORKS_ACL="127.0.0.1, ::1"

ENV DNSDIST_UPSTREAM_CHECK_INTERVAL=10
ENV DNSDIST_UPSTREAM_POOL_NAME="upstream"

ENV DNSDIST_RATE_LIMIT_DISABLE=false
ENV DNSDIST_RATE_LIMIT_WARN=800
ENV DNSDIST_RATE_LIMIT_BLOCK=1000
ENV DNSDIST_RATE_LIMIT_BLOCK_DURATION=360
ENV DNSDIST_RATE_LIMIT_EVAL_WINDOW=60

ENV DYNDNS_CRON_SCHEDULE="*/1 * * * *"

# ---------- HEALTHCHECK ----------
HEALTHCHECK --interval=30s --timeout=3s CMD (pgrep "dnsdist" > /dev/null) || exit 1

# ---------- Build Info ----------
RUN echo "I'm building for $TARGETPLATFORM"

# ---------- Base System ----------
RUN apk update && apk upgrade

# ---------- Create Non-root User ----------
RUN addgroup minidns && adduser -D -H -G minidns minidns

# ---------- Install Packages ----------
RUN apk add --no-cache \
  jq tini dnsdist curl bash gnupg procps \
  ca-certificates openssl dog bind-tools \
  lua5.4-filesystem ipcalc libcap supercronic \
  step-cli nano && \
  rm -rf /var/cache/apk/*

# ---------- Grant CAP_NET_BIND_SERVICE to dnsdist ----------
RUN setcap 'cap_net_bind_service=+ep' /usr/bin/dnsdist

# ---------- Setup Directory Structure ----------
RUN mkdir -p /etc/dnsdist/conf.d \
    /etc/dnsdist/certs \
    /etc/minidns/ && \
    touch /etc/dnsdist/allowedClients.acl \
          /etc/dnsdist/allowedClients.conf

# ---------- Copy Configs & Scripts ----------
COPY dnsdist.conf.template /etc/dnsdist/dnsdist.conf.template
COPY minidns.conf /etc/dnsdist/conf.d/minidns.conf
COPY domainrules.conf /etc/dnsdist/conf.d/domainrules.conf

COPY entrypoint.sh /entrypoint.sh
COPY generateACL.sh /generateACL.sh
COPY dynDNSCron.sh /dynDNSCron.sh

# ---------- Set Ownership and Permissions ----------
RUN chown -R minidns:minidns /etc/dnsdist /etc/minidns && \
    chmod +x /entrypoint.sh /generateACL.sh /dynDNSCron.sh && \
    chmod 644 /etc/dnsdist/allowedClients.acl /etc/dnsdist/allowedClients.conf

# ---------- Switch to minidns User ----------
USER minidns

# ---------- Entrypoint ----------
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/bash", "/entrypoint.sh"]