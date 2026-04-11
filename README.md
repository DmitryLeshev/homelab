# Homelab Infra v2

Этот каталог запускает Terraform через Docker Compose и Makefile.

## Быстрый старт

1. Перейдите в каталог v2.
2. Проверьте значения в terraform/proxmox/terraform.tfvars.
3. Выполните безопасный прогон с форматированием и валидацией:

```bash
make plan-auto-fix
```

## Основные команды

```bash
make init
make plan
make plan-auto-fix
make apply
make destroy
```

## Что делает plan-auto-fix

Цель выполняет шаги по порядку:

1. terraform init
2. terraform fmt -recursive
3. terraform validate
4. terraform plan -var-file=terraform.tfvars

## Переопределяемые параметры

По умолчанию в Makefile:

- TF_DIR=terraform/proxmox
- TF_VARS_FILE=terraform.tfvars

Пример запуска с переопределением каталога:

```bash
make plan TF_DIR=terraform/proxmox
```
