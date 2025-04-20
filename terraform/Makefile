.PHONY: init plan apply destroy ssh-key validate

init:
	terraform init

validate:
	terraform validate

plan:
	terraform plan

apply:
	terraform apply

destroy:
	terraform destroy

ssh-key:
	cd scripts && chmod +x generate_ssh_key.sh && ./generate_ssh_key.sh

bootstrap: ssh-key init plan
	@echo "Ready to run 'make apply' to deploy infrastructure"

clean-all: destroy
	rm -f terraform.tfstate*
	rm -f scripts/stf-proj-key.pem
