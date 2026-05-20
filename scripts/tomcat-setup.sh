#!/bin/bash

# --- system update ---
sudo apt update -y

# --- insalling tomcat ---
wget -O tomcat.zip https://dlcdn.apache.org/tomcat/tomcat-11/v11.0.22/bin/apache-tomcat-11.0.22.zip

# --- insalling zip ---
sudo apt insatll zip -y
unzip tomcat.zip
