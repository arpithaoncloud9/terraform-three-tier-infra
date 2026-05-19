.PHONY: help init fmt validate plan apply destroy show output clean

help:
	@echo "Available targets:"
	@echo "  init      - Initialize Terraform (downloads providers, sets up backend)"
	@echo "  fmt       - Format all Terraform files"
	@echo "  validate  - Validate Terraform configuration"
	@echo "  plan      - Show what Terraform will change"
	@echo "  apply     - Apply changes (with confirmation)"
	@echo "  destroy   - Destroy all managed infrastructure"
	@echo "  show      - Show current state"
	@echo "  output    - Show output values"
	@echo "  clean     - Remove local .terraform directories and plan files"

init:
	terraform init

fmt:
	terraform fmt -recursive

validate:
	terraform validate

plan:
	terraform plan -out=tfplan

apply:
	terraform apply tfplan

destroy:
	terraform destroy

show:
	terraform show

output:
	terraform output

clean:
	rm -rf .terraform/ tfplan
	find . -type d -name ".terraform" -exec rm -rf {} +
	find . -type f -name "tfplan" -delete