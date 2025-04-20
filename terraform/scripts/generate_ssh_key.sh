#!/bin/bash

KEY_NAME="stf-proj-key"

if [ -f "${KEY_NAME}.pem" ]; then
  echo "Key ${KEY_NAME}.pem already exists. Skipping creation."
else
  echo "Generating SSH key pair ${KEY_NAME}..."
  aws ec2 create-key-pair --key-name ${KEY_NAME} --query 'KeyMaterial' --output text > ${KEY_NAME}.pem
  chmod 400 ${KEY_NAME}.pem
  echo "SSH key pair created and saved to ${KEY_NAME}.pem"
  echo "Remember to keep this file secure!"
fi
