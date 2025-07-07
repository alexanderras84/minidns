FROM alpine:3.20
ARG TARGETPLATFORM

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

# HEALTHCHECKS
HEALTHCHECK --interval=30s --timeout=3s CMD (pgrep "dnsdist" > /dev/null) || exit 1

# Expose Ports
EXPOSE 5300/udp

RUN echo "I'm building for $TARGETPLATFORM"

# Update Base
RUN apk update && apk upgrade

# Create Users
RUN addgroup minidns && adduser -D -H -G minidns minidns

# Install needed packages and clean up
RUN apk add --no-cache jq tini dnsdist curl bash gnupg procps ca-certificates openssl dog bind-tools lua5.4-filesystem ipcalc libcap supercronic step-cli nano && \
    rm -rf /var/cache/apk/*

# Setup Folder(s)
RUN mkdir -p /etc/dnsdist/conf.d && \
    mkdir -p /etc/dnsdist/certs && \
    mkdir -p /etc/minidns/

# Copy Files
COPY dnsdist.conf.template /etc/dnsdist/dnsdist.conf.template
COPY minidns.conf /etc/dnsdist/conf.d/minidns.conf

COPY entrypoint.sh /entrypoint.sh
COPY generateACL.sh /generateACL.sh
COPY dynDNSCron.sh /dynDNSCron.sh

RUN chown -R minidns:minidns /etc/dnsdist/ && \
    chown -R minidns:minidns /etc/minidns/ && \
    chmod +x /entrypoint.sh && \
    chmod +x /generateACL.sh && \
    chmod +x dynDNSCron.sh

USER minidns

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/bash", "/entrypoint.sh"]
