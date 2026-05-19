#!/bin/bash
# ============================================================
# Jenkins EC2 Bootstrap Script
# Ubuntu 22.04 — installs Jenkins + Java + Maven + Git
# ============================================================

set -e
exec > /var/log/jenkins-setup.log 2>&1

echo "[$(date)] Starting Jenkins setup..."

# --- Java 17 ---
apt-get update -y
apt-get install -y fontconfig openjdk-17-jre git

# --- Maven ---
apt-get install -y maven

# --- Jenkins ---
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update -y
apt-get install -y jenkins

systemctl enable jenkins
systemctl start jenkins

echo "[$(date)] Jenkins is running on port 8080"
echo "[$(date)] Initial admin password:"
cat /var/lib/jenkins/secrets/initialAdminPassword
