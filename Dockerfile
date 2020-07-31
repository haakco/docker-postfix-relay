FROM alpine


# You can set this variables when running the image to override the host name or
# foward the messages to another server
# ENV  HOSTNAME
# Hostname that will be used in the outgoing mail
# ENV  RELAYHOST
# The relay host for this server
# ENV  ALLOWED_SENDER_DOMAINS
# Limit the list of sending domains to this list only

ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    TZ="Africa/Johannesburg" \
    TERM="xterm"

ARG HTTPS_PROXY=""
ARG HTTP_PROXY=""

RUN apk add --no-cache --update \
        bash busybox-extras \
        ca-certificates\
        cyrus-sasl cyrus-sasl-dev  cyrus-sasl-crammd5 cyrus-sasl-login cyrus-sasl-digestmd5 cyrus-sasl-scram libgsasl \
        libsasl cyrus-sasl-gssapiv2 cyrus-sasl-gs2 cyrus-sasl-openrc cyrus-sasl-ntlm cyrus-sasl-plain \
        mailx \
        postfix \
        rsyslog \
        supervisor && \
    apk add --no-cache --update \
        pcre icu-libs \
        db libpq \
        libsasl \
        libldap && \
    rm -rf /tmp/* && \
    rm -rf /var/cache/apk/*

COPY ./files/supervisord.conf /supervisord.conf
COPY ./files/rsyslog.conf /etc/rsyslog.conf
COPY ./files/dfg.sh /usr/local/bin/dfg.sh

COPY ./files/start.sh /start.sh

RUN chmod u+x \
    /start.sh \
    /usr/local/bin/dfg.sh

RUN chmod u+x  /start.sh && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime

ENV SMTP_USER="" \
    SMTP_PASS="" \
    RELAY_HOST="" \
    HOST_NAME="" \
    MY_DOMAIN="" \
    DEFAULT_EMAIL="" \
    ALLOWED_SENDER_DOMAINS="" \
    SMTP_HELO_NAME="" \
    ADD_HEADERS=""

VOLUME  [ "/data" ]

USER root
WORKDIR /tmp

EXPOSE 25 587
CMD ["/start.sh"]
