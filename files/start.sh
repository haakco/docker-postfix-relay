#!/usr/bin/env bash
RELAY_HOST=${RELAY_HOST:-""}
SMTP_USER=${SMTP_USER:-""}
SMTP_PASS=${SMTP_PASS:-""}
MY_DOMAIN=${MY_DOMAIN:-""}
ALLOWED_SENDER_DOMAINS=${ALLOWED_SENDER_DOMAINS:-""}
HOST_NAME=${HOST_NAME:-""}
ADD_HEADERS=${ADD_HEADERS:-""}
DEFAULT_EMAIL=${DEFAULT_EMAIL:-""}
SMTP_HELO_NAME=${SMTP_HELO_NAME:-""}
MYNETWORKS=${MYNETWORKS:-"127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"}

mkdir -p /data/postfix_spool
mkdir -p /data/postfix_config
mkdir -p /data/logs/supervisor
mkdir -p /data/logs/postfix

if [[ ! -f /data/postfix_config/main.cf ]]; then
  mv /etc/postfix/* /data/postfix_config/
fi

rm -rf /etc/postfix
ln -sf /data/postfix_config /etc/postfix

rm -rf /var/spool/postfix
ln -sf /data/postfix_spool /var/spool/postfix

postconf -e daemon_directory=/usr/libexec/postfix

postconf -e queue_directory=/data/postfix_spool

# Disable SMTPUTF8, because libraries (ICU) are missing in alpine
postconf -e smtputf8_enable=no

# Update aliases database. It's not used, but postfix complains if the .db file is missing
postalias /etc/postfix/aliases

# Disable local mail delivery
postconf -e mydestination=
# Don't relay for any domains
postconf -e relay_domains=

# Reject invalid HELOs
postconf -e smtpd_delay_reject=yes
postconf -e smtpd_helo_required=yes
postconf -e "smtpd_helo_restrictions=permit_mynetworks,reject_invalid_helo_hostname,permit"

# Set up host name
if [[ ! -z "${HOST_NAME}" ]]; then
    postconf -e myhostname=${HOST_NAME}
else
    postconf -e myhostname=${HOSTNAME}
fi

# Set up a relay host, if needed
if [[ ! -z "${RELAY_HOST}" ]]; then
    postconf -e relayhost=${RELAY_HOST}
    if [[ ! -z "${SMTP_USER}" ]]; then
      postconf -e 'smtp_sasl_auth_enable=yes'
      postconf -e 'smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd'
#      postconf -e 'smtp_sasl_security_options='
      postconf -e 'smtp_sasl_security_options=noanonymous'
      postconf -e 'smtp_sasl_tls_security_options=noanonymous'
      postconf -e 'smtp_tls_security_level=encrypt'
      postconf -e 'smtp_use_tls=yes'
      postconf -e 'smtp_tls_session_cache_database=btree:${data_directory}/smtp_scache'
      postconf -e 'smtp_tls_CAfile=/etc/ssl/certs/ca-certificates.crt'
      postconf -e 'header_size_limit=4096000'

      echo "${RELAY_HOST}   ${SMTP_USER}:${SMTP_PASS}" > /etc/postfix/sasl_passwd
      chown root:root /etc/postfix/sasl_passwd
      chmod 600 /etc/postfix/sasl_passwd
      postmap /etc/postfix/sasl_passwd
    fi
else
    postconf -e relayhost
fi

# Set up my networks to list only networks in the local loopback range
#network_table=/etc/postfix/network_table
#touch $network_table
#echo "127.0.0.0/8    any_value" >  $network_table
#echo "10.0.0.0/8     any_value" >> $network_table
#echo "172.16.0.0/12  any_value" >> $network_table
#echo "192.168.0.0/16 any_value" >> $network_table
## Ignore IPv6 for now
##echo "fd00::/8" >> $network_table
#postmap $network_table
#postconf -e mynetworks=hash:$network_table
postconf -e "mynetworks=127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"

# Split with space
if [[ ! -z "${ALLOWED_SENDER_DOMAINS}" ]]; then
    echo "Setting up allowed SENDER domains:"
    allowed_senders=/etc/postfix/allowed_senders
    rm -f $allowed_senders $allowed_senders.db > /dev/null
    touch $allowed_senders
    for i in ${ALLOWED_SENDER_DOMAINS}; do
        echo -e "\t$i"
        echo -e "$i\tOK" >> $allowed_senders
    done
    postmap $allowed_senders

    postconf -e "smtpd_restriction_classes=allowed_domains_only"
    postconf -e "allowed_domains_only=permit_mynetworks, reject_non_fqdn_sender reject"
    postconf -e "smtpd_recipient_restrictions=reject_non_fqdn_recipient, reject_unknown_recipient_domain, reject_unverified_recipient, check_sender_access hash:$allowed_senders, reject"
else
    postconf -e "smtpd_restriction_classes="
    postconf -e "smtpd_recipient_restrictions=reject_non_fqdn_recipient,reject_unknown_recipient_domain,reject_unverified_recipient"
fi

if [[ ! -z "${DEFAULT_EMAIL}" ]]; then
    echo "root:          ${DEFAULT_EMAIL}" >> /etc/aliases
    newaliases
fi

if [[ ! -z "${MY_DOMAIN}" ]]; then
    postconf -e "mydomain=${MY_DOMAIN}"
    postconf -e "sender_canonical_maps=hash:/etc/postfix/canonical"

    echo "root@${MY_DOMAIN}   server@${MY_DOMAIN}" > /etc/postfix/canonical
    echo "root@${HOST_NAME}   server@${MY_DOMAIN}" >> /etc/postfix/canonical
    postmap /etc/postfix/canonical
fi

# Set up host name
if [[ ! -z "${ADD_HEADERS}" ]]; then
    postconf -e 'header_checks=regexp:/etc/postfix/my_custom_header'
    echo "${ADD_HEADERS}" > /etc/postfix/my_custom_header
fi

postconf -e 'message_size_limit=0'

if [[ ! -z "${SMTP_HELO_NAME}" ]]; then
  postconf -e "smtp_helo_name=${SMTP_HELO_NAME}"
  postconf -e "smtp_always_send_ehlo=yes"
fi

# Use 587 (submission)
sed -i -r -e 's/^#submission/submission/' /etc/postfix/master.cf

/usr/bin/supervisord -n -c /supervisord.conf
