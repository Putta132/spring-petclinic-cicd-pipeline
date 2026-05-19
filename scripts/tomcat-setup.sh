#!/bin/bash
# ============================================================
# Apache Tomcat EC2 Bootstrap Script
# Ubuntu 22.04 — installs Tomcat 10.x
# ============================================================

set -e
exec > /var/log/tomcat-setup.log 2>&1

echo "[$(date)] Starting Tomcat setup..."

# --- Java 17 ---
apt-get update -y
apt-get install -y openjdk-17-jre wget

# --- Create tomcat user ---
useradd -m -d /opt/tomcat tomcat || true

# --- Download Tomcat ---
cd /opt
wget https://downloads.apache.org/tomcat/tomcat-10/v10.1.18/bin/apache-tomcat-10.1.18.tar.gz
tar -xzf apache-tomcat-10.1.18.tar.gz
mv apache-tomcat-10.1.18 tomcat
chown -R tomcat:tomcat /opt/tomcat

# --- Enable Manager App for Jenkins deploy ---
cat > /opt/tomcat/conf/tomcat-users.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users>
  <role rolename="manager-gui"/>
  <role rolename="manager-script"/>
  <role rolename="admin-gui"/>
  <user username="admin" password="Admin@123" roles="manager-gui,manager-script,admin-gui"/>
</tomcat-users>
EOF

# --- Allow remote access to Manager ---
cat > /opt/tomcat/webapps/manager/META-INF/context.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true">
</Context>
EOF

# --- Systemd service ---
cat > /etc/systemd/system/tomcat.service <<EOF
[Unit]
Description=Apache Tomcat
After=network.target

[Service]
Type=forking
User=tomcat
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
Environment="CATALINA_HOME=/opt/tomcat"
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable tomcat
systemctl start tomcat

echo "[$(date)] Tomcat running on port 8080"
