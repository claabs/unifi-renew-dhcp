########
# BASE
########
FROM alpine:3

LABEL org.opencontainers.image.title="unifi-renew-dhcp" \ 
    org.opencontainers.image.url="https://github.com/claabs/unifi-renew-dhcp" \
    org.opencontainers.image.description="Renew DHCP when the internet goes out" \
    org.opencontainers.image.name="unifi-renew-dhcp" \
    org.opencontainers.image.base.name="alpine:3" \
    org.opencontainers.image.version="latest"

WORKDIR /app

RUN apk add --no-cache \
    openssh \
    sshpass \
    tzdata \
    tini \
    coreutils

COPY *.sh .

VOLUME [ "/data" ]

ENTRYPOINT ["tini", "--", "/app/entrypoint.sh"]
