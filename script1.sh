#!/bin/bash

apt-get update -y
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

docker pull gayatri491/frontend_app3:latest 
docker run -d -p 80:80 gayatri491/frontend_app3:latest
