#!/bin/bash
# ============================================================
# SonarQube EC2 Bootstrap Script
# Ubuntu 22.04 — installs SonarQube 10.x (Community Edition)
# ============================================================

set -e
exec > /var/log/sonarqube-setup.log 2>&1

echo "[$(date)] Starting SonarQube setup..."

# --- Java 17 ---
apt-get update -y
apt-get install -y openjdk-17-jre unzip wget

# --- Kernel settings required by SonarQube (Elasticsearch) ---
sysctl -w vm.max_map_count=524288
sysctl -w fs.file-max=131072
echo "vm.max_map_count=524288" >> /etc/sysctl.conf
echo "fs.file-max=131072"      >> /etc/sysctl.conf

# --- Create sonar user ---
useradd -m -d /opt/sonarqube sonar || true

# --- Download SonarQube ---
cd /opt
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.3.0.82913.zip
unzip sonarqube-10.3.0.82913.zip
mv sonarqube-10.3.0.82913 sonarqube
chown -R sonar:sonar /opt/sonarqube

# --- Systemd service ---
cat > /etc/systemd/system/sonarqube.service <<EOF
[Unit]
Description=SonarQube
After=network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonar
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sonarqube
systemctl start sonarqube

echo "[$(date)] SonarQube starting on port 9000 (takes ~2 mins to boot)"
