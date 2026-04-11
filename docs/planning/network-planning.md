# Network Planning

## Goal
Спроектировать адресацию и ingress-путь до установки кластера.

## Decisions To Make Before Deployment
1. Node subnet и gateway.
2. MetalLB pool subnet (должен быть достижим из клиентской сети).
3. Cilium mode: kubeProxyReplacement, routingMode, masquerade.
4. DNS план: какие домены и куда резолвятся.
5. Требования firewall/NAT для pod egress.

## Validation Plan
- Проверка node-to-node connectivity.
- Проверка pod DNS (`kube-dns`) и HTTPS egress из pod.
- Проверка reachability LoadBalancer IP с клиентской машины.

## Common Failure Risks
- Pool MetalLB в другой VLAN без маршрутизации.
- Неработающий pod egress (Flux не может тянуть Git).
- Несогласованные ручные Helm values и GitOps values.
