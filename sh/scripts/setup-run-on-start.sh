#!/bin/bash -x

cat <<'EOF' > /usr/local/bin/run-on-start.sh
#!/bin/bash
[[ -x /host/scripts/run-on-start.sh ]] && /host/scripts/run-on-start.sh
:    # return 0 anyway
EOF
chmod +x /usr/local/bin/run-on-start.sh

cat <<EOF > /etc/systemd/system/run-on-start.service
[Unit]
Description=Create a tun device
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/run-on-start.sh

[Install]
WantedBy=multi-user.target
EOF

systemctl enable run-on-start.service
systemctl start run-on-start.service
