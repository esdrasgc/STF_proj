#!/bin/bash

KEY_NAME="stf-proj-key"
REGIONS=("us-east-1" "us-west-2" "eu-west-1" "eu-central-1" "ap-southeast-1" "sa-east-1")

# Create the key pair once locally if it doesn't exist
if [ ! -f "${KEY_NAME}.pem" ]; then
  echo "Generating SSH key pair locally as ${KEY_NAME}.pem..."
  aws ec2 create-key-pair --key-name ${KEY_NAME} --query 'KeyMaterial' --output text > ${KEY_NAME}.pem
  chmod 400 ${KEY_NAME}.pem
  echo "SSH key pair created and saved to ${KEY_NAME}.pem"
else
  echo "Key ${KEY_NAME}.pem already exists locally."
fi

# Extract the public key from the private key
if [ ! -f "${KEY_NAME}.pub" ]; then
  echo "Extracting public key from private key..."
  ssh-keygen -y -f ${KEY_NAME}.pem > ${KEY_NAME}.pub
  echo "Public key extracted and saved to ${KEY_NAME}.pub"
fi

# # Import the key to all regions
# echo "Importing key to all regions..."
# for region in "${REGIONS[@]}"; do
#   echo "Checking region: $region"
  
#   # Check if key exists in the region
#   if aws ec2 describe-key-pairs --region $region --key-names $KEY_NAME 2>&1 | grep -q "InvalidKeyPair.NotFound"; then
#     echo "Key doesn't exist in $region. Creating..."
#     aws ec2 import-key-pair --region $region --key-name $KEY_NAME --public-key-material fileb://${KEY_NAME}.pub
#     echo "Key imported to $region"
#   else
#     echo "Key already exists in $region. Skipping."
#   fi
# done

# echo "SSH key setup complete for all regions!"
