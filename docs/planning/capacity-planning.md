# Capacity Planning

## Goal
Оценить ресурсы до внедрения и избежать деградации control-plane/ingress.

## What To Estimate
1. Control-plane ресурсы (etcd, API server, controllers).
2. System workloads (`cilium`, `traefik`, `cert-manager`, `flux-*`).
3. Application workloads (requests/limits).
4. Storage requirements и рост логов.

## Practical Baseline For This Repository
- Критичные контроллеры должны иметь стабильный запас CPU/Memory.
- Минимизировать co-location всех control компонентов на одном узле.
- Наблюдать restart loops и queue lag в Flux контроллерах.

## Capacity Review Triggers
- Добавление новых ingress-heavy приложений.
- Рост числа HelmRelease/Kustomization.
- Увеличение числа нод/namespace.
