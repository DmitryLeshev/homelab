# Recover Flux After Network Incident

## Purpose
Быстро восстановить Flux reconciliation после проблем сети/CNI.

## Context
Сценарий: `GitRepository` timeout, `Kustomization` stuck, контроллеры в CrashLoop.

## Steps
1. Проверить сеть в pod.
```bash
kubectl run netcheck --rm -i --restart=Never --image=curlimages/curl:8.12.1 -- \
  sh -lc 'nslookup github.com 10.43.0.10; curl -I --max-time 15 https://github.com'
```
2. Проверить Cilium/CoreDNS.
```bash
kubectl -n kube-system exec ds/cilium -- cilium status
kubectl -n kube-system logs deploy/coredns --tail=200
```
3. Выполнить reconcile ядра Flux.
```bash
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization infra-cilium -n flux-system --with-source
flux reconcile kustomization flux-system -n flux-system --with-source
```
4. При необходимости вручную дожать зависимые kustomization.
```bash
flux reconcile kustomization infra-cert-manager -n flux-system --with-source
flux reconcile kustomization infra-cert-manager-config -n flux-system --with-source
```

## Validation
```bash
flux get sources git -A
flux get kustomizations -A
flux get helmreleases -A
kubectl -n flux-system get pods
```

## Pitfalls
- Лечить Flux до восстановления pod egress.
- Использовать разные Cilium values вручную и в Git.
- Пропустить `sops-age` для decryption-ветки.

## Rollback
1. Вернуть последний рабочий commit инфраструктуры.
2. Повторить reconcile цепочки.
