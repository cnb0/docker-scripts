#!/bin/bash -x

# fix a bug with systemd on ubuntu:20.04
# see: https://jira.mariadb.org/browse/MDEV-23050
sed -i /lib/systemd/system/mariadb.service \
    -e '/SendSIGKILL/ c SendSIGKILL=yes'
systemctl daemon-reload
systemctl restart mariadb

### regenerate the password of debian-sys-maint
passwd=$(mcookie | head -c 16)
mysql --defaults-file=/etc/mysql/debian.cnf -B \
    -e "SET PASSWORD FOR 'debian-sys-maint'@'localhost' = PASSWORD('$passwd');" &&
sed -i /etc/mysql/debian.cnf \
    -e "/^password/c password = $passwd"

### set the password for the root user of mysql
passwd=$(mcookie | head -c 16)
query="update mysql.user set authentication_string=PASSWORD(\"$passwd\") where User=\"root\"; flush privileges;"
debian_cnf=/etc/mysql/debian.cnf
mysql --defaults-file=$debian_cnf -B -e "$query"
