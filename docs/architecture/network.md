# Network Topology

## Baseline
- Node subnet: `10.10.30.0/24` (example from current cluster).
- Kubernetes service CIDR: managed by K3s (`10.43.0.0/16` by default).
- Pod CIDR: managed by Kubernetes + Cilium IPAM.

## CNI Model
- K3s запускается с `--flannel-backend=none`.
- Cilium используется как primary CNI.
- Рабочая конфигурация для текущего стенда:
  - `kubeProxyReplacement=true`
  - `ipam.mode=kubernetes`
  - `bpf.masquerade=true`
  - `enableIPv4Masquerade=true`
  - `routingMode=tunnel`
  - `tunnelProtocol=vxlan`

## Ingress and Load Balancing
- Traefik service type: `LoadBalancer`.
- External IP выдается MetalLB из `IPAddressPool`.
- Для L2-режима MetalLB пул должен быть в сети, достижимой на уровне L2/L3 для клиентов.

## Current Practical Rules
- Не смешивать пул MetalLB из одной VLAN и узлы из другой без явной маршрутизации.
- До bootstrap Flux обязательно проверить pod DNS + HTTPS egress.
- Если ingress-домен резолвится, но не открывается, сначала проверять reachability IP LoadBalancer, затем Ingress.

## Alternatives
- Direct routing вместо VXLAN:
  - Плюсы: меньше overlay overhead.
  - Минусы: выше требования к underlay маршрутизации PodCIDR.
- BGP для MetalLB:
  - Плюсы: более предсказуемая маршрутизация между VLAN.
  - Минусы: сложнее эксплуатация в homelab.
