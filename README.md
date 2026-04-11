# Homelab Infrastructure

Репозиторий для управления homelab-инфраструктурой:
- Terraform (Proxmox VM provisioning)
- Kubernetes GitOps (Flux + Kustomize + HelmRelease)
- Секреты через SOPS/age

## Repository Layout

- `terraform/proxmox` — Terraform стек для Proxmox
- `clusters/prod` — GitOps-манифесты кластера `prod`
- `docs` — инженерная документация (architecture/planning/runbooks/incidents/reference)
- `Makefile` — единая точка запуска Terraform и проверок манифестов

## Prerequisites

- Docker + Docker Compose
- `kubectl`
- доступ к кластеру (kubeconfig)
- для SOPS workflow: `sops`, `age`

## Quick Start (Terraform)

Проверьте значения в `terraform/proxmox/terraform.tfvars`, затем выполните:

```bash
make plan-auto-fix
```

`plan-auto-fix` делает:
1. `terraform init`
2. `terraform fmt -recursive`
3. `terraform validate`
4. `terraform plan -var-file=terraform.tfvars`

## Common Targets

```bash
make init
make plan
make plan-auto-fix
make apply
make apply-auto
make destroy
make destroy-auto
make validate
make fmt
make fmt-check
make output
make state-list
```

## Kubernetes Manifest Validation

```bash
make validate-clusters
make validate-clusters-server
make validate-clusters-flux
```

- `validate-clusters` — `kubectl kustomize` для ключевых путей `clusters/prod`
- `validate-clusters-server` — `kubectl apply --dry-run=server`
- `validate-clusters-flux` — `kubeconform` по собранным манифестам

## Makefile Overrides

Параметры по умолчанию:
- `TF_DIR=terraform/proxmox`
- `TF_VARS_FILE=terraform.tfvars`
- `CLUSTER_DIR=clusters/prod`

Пример:

```bash
make plan TF_DIR=terraform/proxmox TF_VARS_FILE=terraform.tfvars
```

## Documentation Entry Point

Начинайте с:

- `docs/1.main.md`

Ключевые runbooks:
- `docs/runbooks/install-k3s-with-cilium.md`
- `docs/runbooks/bootstrap-flux.md`
- `docs/runbooks/recover-flux-after-network-incident.md`

