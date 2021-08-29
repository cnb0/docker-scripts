#!/bin/bash -x

a2enmod ssl proxy proxy_http rewrite
a2ensite 000-default default-ssl

# redirect all http requests to https
sed -i /etc/apache2/sites-available/000-default.conf \
    -e '/<VirtualHost \*:80>/ a\' \
    -e '\t### redirect http to https\' \
    -e '\tRewriteEngine On\' \
    -e '\tRewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI}\' \
    -e ""

### restart apache2
systemctl restart apache2
