#!/bin/bash

# --- system update ---
sudo apt-get update -y

# --- installing Java 21 ---
sudo apt install -y openjdk-21-jdk 

# --- installing sonarqube---
wget -O sonar.zip https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-26.5.0.122743.zip?_gl=1*1idv8m7*_gcl_au*NjQzNTEwODI3LjE3NzkwNjAyMjI.
*_ga*MzE0MDg2NzcuMTc3OTA2MDIyMQ..*_ga_9JZ0GZ5TC6*czE3NzkyNTcxNTgkbzQkZzEkdDE3NzkyNTcxNjIkajU3JGwwJGgw

# --- installing zip---
sudo apt install zip -y
unzip sonar.zip
