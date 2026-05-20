#!/bin/bash

# --- system update ---
sudo apt update -y

# --- Java 17 ---
sudo apt install -y openjdk-21-jdk

# --- Download Nexus ---
sudo wget -O nexus.tar.gz https://download.sonatype.com/nexus/3/nexus-3.92.2-01-linux-x86_64.tar.gz

# --- Extract Nexus ---
tar -xvzf nexus.tar.gz


