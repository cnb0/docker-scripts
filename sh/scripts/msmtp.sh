#!/bin/bash -x

source /host/settings.sh

[[ -z $SMTP_SERVER ]] && [[ -z $GMAIL_ADDRESS ]] && exit 0

# make sure that the right packages are installed
apt purge --yes mailutils mailutils-common
apt autoremove --yes
apt install --yes msmtp msmtp-mta bsd-mailx

if [[ -n $SMTP_SERVER ]]; then
    cat <<-_EOF > /etc/msmtprc
host $SMTP_SERVER
maildomain $SMTP_DOMAIN
tls_starttls on
auto_from on
aliases /etc/aliases.msmtp
syslog LOG_MAIL
_EOF
    forward_address=${ADMIN_EMAIL:-${FORWARD_ADDRESS:-admin@$SMTP_DOMAIN}}
elif [[ -n $GMAIL_ADDRESS ]]; then
    cat <<-_EOF > /etc/msmtprc
host smtp.gmail.com
port 587
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
tls_starttls on
aliases /etc/aliases.msmtp
syslog LOG_MAIL

from $GMAIL_ADDRESS
auth on
user $GMAIL_ADDRESS
password $GMAIL_PASSWD
_EOF
    forward_address=${ADMIN_EMAIL:-${FORWARD_ADDRESS:-$GMAIL_ADDRESS}}
fi

# forward all local emails
cat <<-_EOF > /etc/aliases.msmtp
default: $forward_address
_EOF
