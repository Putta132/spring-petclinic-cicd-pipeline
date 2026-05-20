#!/bin/bash

# --- Java 21 ---
sudo apt update -y
sudo apt install -y openjdk-21-jdk

# --- Maven ---
sudo apt install -y maven

# --- Jenkins ---
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins


systemctl enable jenkins
systemctl start jenkins

echo "[$(date)] Jenkins is running on port 8080"
echo "[$(date)] Initial admin password:"
cat /var/lib/jenkins/secrets/initialAdminPassword
