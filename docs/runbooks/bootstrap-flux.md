# Bootstrap Flux

## Purpose
Подключить кластер к GitOps репозиторию и запустить reconciliation.

## Context
Применять после того, как Cilium и pod egress подтверждены.

## Steps
1. Экспортировать валидный GitHub token.
```bash
export GITHUB_TOKEN="<VALID_GITHUB_PAT>"
```
2. Выполнить bootstrap.
```bash
flux bootstrap github \
  --owner=DmitryLeshev \
  --repository=homelab \
  --branch=main \
  --path=clusters/prod \
  --personal \
  --token-auth
```
3. Если bootstrap уже был ранее, использовать reconcile вместо повторного bootstrap.
```bash
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization flux-system -n flux-system --with-source
```

## Validation
```bash
flux get sources git -A
flux get kustomizations -A
flux get helmreleases -A
kubectl -n flux-system get pods
```

## Pitfalls
- Токен есть локально, но невалидный в кластере.
- Pod egress не работает, `GitRepository` уходит в timeout.
- Попытка лечить Flux до фикса сети.

## Rollback
1. Исправить сетевой путь pod->GitHub.
2. Обновить secret/credential для Flux источника.
3. Повторить reconcile.
