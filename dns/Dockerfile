from docker.io/ubuntu/bind9:latest

COPY named.config.local /etc/bind
COPY external.zone /etc/bind
COPY internal.zone /etc/bind
COPY rev.external.zone /etc/bind
COPY rev.internal.zone /etc/bind