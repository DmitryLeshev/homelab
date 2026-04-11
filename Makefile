DOCKER ?= sudo docker
COMPOSE_FILE ?= docker-compose.yml
TF_SERVICE ?= terraform

# Default Terraform stack inside v2
TF_DIR ?= terraform/proxmox
TF_VARS_FILE ?= terraform.tfvars
CLUSTER_DIR ?= clusters/prod

TF := $(DOCKER) compose -f $(COMPOSE_FILE) run --rm $(TF_SERVICE) -chdir=$(TF_DIR)
KC := $(DOCKER) compose -f $(COMPOSE_FILE) run --rm -T kubeconform
CLUSTER_KUSTOMIZE_PATHS := \
	$(CLUSTER_DIR) \
	$(CLUSTER_DIR)/infrastructure/metallb \
	$(CLUSTER_DIR)/infrastructure/metallb-config \
	$(CLUSTER_DIR)/infrastructure/traefik \
	$(CLUSTER_DIR)/infrastructure/cert-manager \
	$(CLUSTER_DIR)/infrastructure/cert-manager-config \
	$(CLUSTER_DIR)/apps/whoami \
	$(CLUSTER_DIR)/apps/app-test-secret

.PHONY: help init plan plan-auto-fix apply apply-auto destroy destroy-auto validate fmt fmt-check output state-list validate-clusters validate-clusters-server validate-clusters-flux

help:
	@echo "Terraform via Docker Compose"
	@echo ""
	@echo "Targets:"
	@echo "  make init"
	@echo "  make plan"
	@echo "  make plan-auto-fix"
	@echo "  make apply"
	@echo "  make apply-auto"
	@echo "  make destroy"
	@echo "  make destroy-auto"
	@echo "  make validate"
	@echo "  make fmt"
	@echo "  make fmt-check"
	@echo "  make validate-clusters"
	@echo "  make validate-clusters-server"
	@echo "  make validate-clusters-flux"
	@echo "  make output"
	@echo "  make state-list"
	@echo ""
	@echo "Overrides:"
	@echo "  TF_DIR=terraform/proxmox (default)"
	@echo "  TF_VARS_FILE=terraform.tfvars (relative to TF_DIR)"
	@echo "  CLUSTER_DIR=clusters/prod (default)"
	@echo ""
	@echo "Example: make plan TF_DIR=terraform/proxmox"

init:
	$(TF) init

plan: init
	$(TF) plan -var-file=$(TF_VARS_FILE)

plan-auto-fix: init
	$(TF) fmt -recursive
	$(TF) validate
	$(TF) plan -var-file=$(TF_VARS_FILE)

apply: init
	$(TF) apply -var-file=$(TF_VARS_FILE)

apply-auto: init
	$(TF) apply -auto-approve -var-file=$(TF_VARS_FILE)

destroy: init
	$(TF) destroy -var-file=$(TF_VARS_FILE)

destroy-auto: init
	$(TF) destroy -auto-approve -var-file=$(TF_VARS_FILE)

validate: init
	$(TF) validate

fmt:
	$(TF) fmt -recursive

fmt-check:
	$(TF) fmt -recursive -check

output: init
	$(TF) output

validate-clusters:
	@set -e; \
	for path in $(CLUSTER_KUSTOMIZE_PATHS); do \
		echo "==> kubectl kustomize $$path"; \
		kubectl kustomize "$$path" >/dev/null; \
	done

validate-clusters-server:
	@set -e; \
	for path in $(CLUSTER_KUSTOMIZE_PATHS); do \
		echo "==> kubectl apply --dry-run=server -k $$path"; \
		kubectl apply --dry-run=server -k "$$path" >/dev/null; \
	done

validate-clusters-flux:
	@set -e; \
	for path in $(CLUSTER_KUSTOMIZE_PATHS); do \
		echo "==> kubeconform $$path"; \
		kubectl kustomize "$$path" | $(KC) \
			-schema-location default \
			-schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
			-ignore-missing-schemas \
			-summary -; \
	done

state-list: init
	$(TF) state list
