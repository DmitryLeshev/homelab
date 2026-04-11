# System Overview

## Purpose
Платформа управляет homelab-кластером через GitOps: желаемое состояние хранится в Git, изменения применяются Flux-контроллерами.

## Core Components
- Kubernetes: K3s cluster (control-plane + agents).
- GitOps: Flux (`source-controller`, `kustomize-controller`, `helm-controller`).
- CNI: Cilium.
- Load Balancing: MetalLB (L2 advertisements).
- Ingress: Traefik.
- TLS automation: cert-manager (+ DNS challenge конфигурация).
- Secret management: SOPS + age (расшифровка в Flux).

## Control Flow
1. Инженер изменяет манифесты в Git.
2. Flux читает GitRepository и синхронизирует `Kustomization`.
3. HelmRelease/Kubernetes ресурсы применяются в кластер.
4. Статус и дрейф контролируются через `flux get ...`.

## Design Decisions
- Git как source of truth: снижает ручные изменения в кластере.
- Декомпозиция на инфраструктурные kustomization: управляемые зависимости (`dependsOn`).
- Cilium до ingress/LB слоев: сначала сеть, затем north-south трафик.

## Trade-offs
- Плюсы: воспроизводимость, аудит, безопасные повторные reconcile.
- Минусы: bootstrap-чувствительность к сетевым проблемам (если pod egress не работает, Flux деградирует).
