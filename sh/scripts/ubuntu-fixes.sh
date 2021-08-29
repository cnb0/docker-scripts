#!/bin/bash -x

### Fix an error message from rsyslog
### See: https://github.com/rsyslog/rsyslog-pkg-ubuntu/issues/74
sed -i /usr/lib/rsyslog/rsyslog-rotate \
    -e 's/systemctl kill -s HUP rsyslog.service/systemctl restart rsyslog.service/'

### customize the shell prompt
source /host/settings.sh
echo $CONTAINER > /etc/debian_chroot
sed -i /root/.bashrc \
    -e '/^#force_color_prompt=/c force_color_prompt=yes'
PS1='\\n\\[\\033[01;32m\\]${debian_chroot:+$debian_chroot }\\[\\033[00m\\]\\u@\\h\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\e[32m\\]\\n==> \\$ \\[\\033[00m\\]'
sed -i /root/.bashrc \
    -e "/^if \[ \"\$color_prompt\" = yes \]/,+2 s/PS1=.*/PS1='$PS1'/"
