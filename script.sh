#!/bin/bash


apt-get update -y
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

echo "DB_HOST=${DB_HOST}" >> /etc/environment
echo "DB_USER=${DB_USER}" >> /etc/environment
echo "DB_PASS=${DB_PASS}" >> /etc/environment
echo "DB_NAME=${DB_NAME}" >> /etc/environment


export DB_HOST=${DB_HOST}
export DB_USER=${DB_USER}
export DB_PASS=${DB_PASS}
export DB_NAME=${DB_NAME}

docker pull gayatri491/backend_app2:latest


docker run -d -p 5000:5000 \
  -e DB_HOST=$DB_HOST \
  -e DB_USER=$DB_USER \
  -e DB_PASS=$DB_PASS \
  -e DB_NAME=$DB_NAME \
  gayatri491/backend_app2:latest
