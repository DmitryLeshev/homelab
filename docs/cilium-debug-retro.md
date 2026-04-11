# Cilium/K3s Incident Debug Retro

Дата: 2026-04-11

## TL;DR
Интернет в подах заработал после запуска Cilium с параметрами:
- `kubeProxyReplacement=true`
- `ipam.mode=kubernetes`
- `bpf.masquerade=true`
- `enableIPv4Masquerade=true`
- `routingMode=tunnel`
- `tunnelProtocol=vxlan`

Ключевой эффект: появился корректный egress/NAT для pod-трафика и стабилизировался datapath service/pod networking.

## Почему именно этот запуск помог
Исходный симптом был: из pod нет доступа наружу (GitHub timeout), DNS в pod не резолвится, Flux `GitRepository` не готов.

Что дали параметры:

1. `ipam.mode=kubernetes`
- Cilium берет pod IP из Kubernetes `PodCIDR`.
- Убрали рассинхрон IPAM между k3s и Cilium.

2. `kubeProxyReplacement=true`
- Cilium полностью берет на себя service load-balancing/eBPF datapath.
- Не нужна зависимость от отдельного kube-proxy path.

3. `bpf.masquerade=true` + `enableIPv4Masquerade=true`
- Явно включили SNAT для egress pod->outside.
- Это критично, когда внешняя сеть не знает pod subnet и ожидает NAT через node IP.

4. `routingMode=tunnel` + `tunnelProtocol=vxlan`
- Гарантированный overlay путь между нодами без требований к underlay L3 маршрутизации pod CIDR.
- Убирает класс проблем с direct-routing в домашней сети/виртуализации.

5. `k8sServiceHost`/`k8sServicePort`
- Явно указали API endpoint control-plane.
- Снижает риск ошибок in-cluster discovery на раннем bootstrap.

## С какой проблемой боролись
Главная проблема: pod-network была нерабочей/несогласованной после серии переустановок и смены CNI режима.

Наблюдаемые симптомы:
- `flux bootstrap` и `source-controller` падали с timeout до GitHub 443.
- `kubectl run ... curl https://github.com` из pod: timeout / resolve error.
- CoreDNS в логах: timeout до upstream DNS (`10.10.30.1`, `8.8.8.8`).
- cert-manager webhook/контроллеры ранее падали из-за недоступности service IP (`10.43.0.1`).
- Часть состояний указывала на сеть в переходном режиме (последствия разных попыток с Cilium/Flannel).

## Инструменты дебага
- `kubectl` (pods/services/endpoints/events/logs/describe)
- `flux` (sources/kustomizations/helmreleases/reconcile)
- `helm` (ручной bootstrap/upgrade Cilium)
- `cilium` CLI внутри DaemonSet (`cilium status`)
- `curlimages/curl` и `busybox` как ephemeral debug pods
- `journalctl`, `systemctl`, `ps` на нодах

## Команды, которые использовали в дебаге

### Flux и статус Git источника
```bash
flux get sources git -A
flux get kustomizations -A
flux get helmreleases -A
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization flux-system -n flux-system --with-source
kubectl -n flux-system describe gitrepository flux-system
kubectl -n flux-system logs deploy/source-controller --tail=200
```

### Проверка Cilium и сетевого пути
```bash
kubectl -n kube-system get pods -l k8s-app=cilium -o wide
kubectl -n kube-system exec ds/cilium -- cilium status
```

### Проверка pod egress/DNS
```bash
kubectl run netcheck --rm -i --restart=Never --image=curlimages/curl:8.12.1 -- \
  sh -lc 'curl -I --max-time 15 https://github.com'

kubectl run dnscheck --rm -i --restart=Never --image=busybox:1.36 -- \
  sh -lc 'cat /etc/resolv.conf; nslookup kubernetes.default.svc.cluster.local; nslookup github.com 10.43.0.10'
```

### CoreDNS диагностика
```bash
kubectl -n kube-system get svc kube-dns -o wide
kubectl -n kube-system get endpoints kube-dns -o wide
kubectl -n kube-system logs deploy/coredns --tail=200
```

### Нодовые проверки
```bash
kubectl get nodes -o wide
systemctl cat k3s | sed -n '1,220p'
ps -ef | grep '[k]3s server'
journalctl -u k3s -b | grep -Ei 'proxy|iptables|nft|cni'
```

## Рабочая команда, после которой ожил pod интернет
```bash
helm upgrade --install cilium cilium/cilium \
  --namespace kube-system \
  --version 1.17.14 \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=10.10.30.14 \
  --set k8sServicePort=6443 \
  --set ipam.mode=kubernetes \
  --set bpf.masquerade=true \
  --set enableIPv4Masquerade=true \
  --set routingMode=tunnel \
  --set tunnelProtocol=vxlan
```

## Что стоит держать как baseline
- После переустановки CNI всегда проверять pod egress до bootstrap Flux.
- Не смешивать разные режимы Cilium (ручной helm values и Flux values должны совпадать).
- Проверять DNS из pod до любых GitOps шагов.
- После инцидента ротировать ранее опубликованные токены/секреты.
