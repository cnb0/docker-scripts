#!/bin/bash -x

source /host/settings.sh

### create a configuration file
cat <<EOF > /etc/apache2/sites-available/default.conf
<VirtualHost *:80>
        ServerName $DOMAIN
        RedirectPermanent / https://$DOMAIN/
</VirtualHost>

<VirtualHost _default_:443>
        ServerName $DOMAIN

        DocumentRoot /var/www/html
        <Directory /var/www/html/>
            AllowOverride All
        </Directory>

        SSLEngine on
        SSLCertificateFile	/etc/ssl/certs/ssl-cert-snakeoil.pem
        SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key

        <FilesMatch "\.(cgi|shtml|phtml|php)$">
                        SSLOptions +StdEnvVars
        </FilesMatch>
</VirtualHost>
EOF

### enable ssl etc.
a2enmod ssl
a2ensite default
a2dissite 000-default
service apache2 restart
