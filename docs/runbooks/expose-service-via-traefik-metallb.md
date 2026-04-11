# Expose Service Via Traefik And MetalLB

## Purpose
Опубликовать HTTP(S) сервис через Traefik Ingress и MetalLB External IP.

## Context
Используется для приложений вида `whoami.24lesh.ru`.

## Steps
1. Проверить пул MetalLB и L2Advertisement.
2. Проверить Traefik `LoadBalancer` service с фиксированным IP в корректной VLAN/subnet.
3. Создать/обновить Ingress с нужным host и TLS secret.
4. Обновить DNS A-запись на фактический External IP Traefik.

## Validation
```bash
kubectl -n traefik get svc traefik -o wide
kubectl get ingress -A -o wide
dig +short whoami.24lesh.ru
curl -v --max-time 10 http://whoami.24lesh.ru
curl -vk --max-time 10 https://whoami.24lesh.ru
```

## Pitfalls
- DNS указывает на IP, который недостижим из клиентской сети.
- MetalLB pool в другой VLAN без корректной маршрутизации.
- Ingress готов, но backend service/pod не ready.

## Rollback
1. Вернуть предыдущий `loadBalancerIP` и пул MetalLB.
2. Откатить DNS запись.
3. Повторно проверить доступность по HTTP/HTTPS.
