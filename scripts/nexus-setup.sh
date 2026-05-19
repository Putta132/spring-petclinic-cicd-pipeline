#!/bin/bash
# ============================================================
# Nexus Repository Manager EC2 Bootstrap Script
# Ubuntu 22.04 — installs Nexus 3.x OSS
# ============================================================

set -e
exec > /var/log/nexus-setup.log 2>&1

echo "[$(date)] Starting Nexus setup..."

# --- Java 17 ---
apt-get update -y
apt-get install -y openjdk-17-jre wget

# --- Create nexus user ---
useradd -m -d /opt/nexus nexus || true

# --- Download Nexus ---
cd /opt
wget https://download.sonatype.com/nexus/3/nexus-3.63.0-01-unix.tar.gz
tar -xzf nexus-3.63.0-01-unix.tar.gz
mv nexus-3.63.0-01 nexus
chown -R nexus:nexus /opt/nexus /opt/sonatype-work 2>/dev/null || true

# --- Run as nexus user ---
echo 'run_as_user="nexus"' > /opt/nexus/bin/nexus.rc

# --- Systemd service ---
cat > /etc/systemd/system/nexus.service <<EOF
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nexus
systemctl start nexus

echo "[$(date)] Nexus starting on port 8081 (takes ~2 mins to boot)"
echo "[$(date)] Default credentials: admin / (check /opt/sonatype-work/nexus3/admin.password)"
