#!/bin/bash -x

source /host/settings.sh

if [[ -n $SMTP_DOMAIN ]]; then
    email_address="root@$SMTP_DOMAIN"
elif [[ -n $GMAIL_ADDRESS ]]; then
    email_address="$GMAIL_ADDRESS"
else
    email_address="root"
fi

if [[ -n $LOGWATCH_EMAIL ]]; then
    email_address=$LOGWATCH_EMAIL
fi

cat <<EOF > /etc/logwatch/conf/logwatch.conf
MailFrom = $CONTAINER logwatch <$email_address>
MailTo = $email_address
Range = between -7 days and -1 days
EOF

mv /etc/cron.daily/00logwatch /etc/cron.weekly/
