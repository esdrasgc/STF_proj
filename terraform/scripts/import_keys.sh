# Import the key pair in the default region
terraform import aws_key_pair.main_key_pair stf-proj-key

# Import the key pair in us-east-1
terraform import -provider=aws.us_east_1 aws_key_pair.us_east_1 stf-proj-key

# Import the key pair in us-west-2
terraform import -provider=aws.us_west_2 aws_key_pair.us_west_2 stf-proj-key

# Import the key pair in eu-west-1
terraform import -provider=aws.eu_west_1 aws_key_pair.eu_west_1 stf-proj-key

# Import the key pair in eu-central-1
terraform import -provider=aws.eu_central_1 aws_key_pair.eu_central_1 stf-proj-key

# Import the key pair in ap-southeast-1
terraform import -provider=aws.ap_southeast_1 aws_key_pair.ap_southeast_1 stf-proj-key

# Import the key pair in sa-east-1
terraform import -provider=aws.sa_east_1 aws_key_pair.sa_east_1 stf-proj-key