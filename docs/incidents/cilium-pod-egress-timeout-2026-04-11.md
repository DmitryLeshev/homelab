# Incident: Cilium Pod Egress Timeout

## Date
2026-04-11

## Symptoms
- `flux bootstrap`/`source-controller` не могли синхронизировать GitRepository.
- Из pod запросы к `https://github.com` завершались timeout.
- DNS в pod был нестабилен или отсутствовал.
- Контроллеры Flux уходили в CrashLoop с ошибками доступа к `https://10.43.0.1:443/api`.

## Root Cause
Сетевой datapath Cilium был в несогласованной конфигурации для данного окружения. В результате pod egress и service path работали нестабильно.

## Resolution
1. Выставлена рабочая конфигурация Cilium:
   - `kubeProxyReplacement=true`
   - `ipam.mode=kubernetes`
   - `bpf.masquerade=true`
   - `enableIPv4Masquerade=true`
   - `routingMode=tunnel`
   - `tunnelProtocol=vxlan`
2. Выполнен reconcile инфраструктурной цепочки Flux.
3. Восстановлен `sops-age` secret для decryption ветки cert-manager.

## Lessons Learned
- Flux readiness зависит от pod egress и DNS.
- Необходимо держать ручные Helm значения идентичными GitOps значениям.
- Проверка сети должна быть обязательным pre-check до bootstrap/reconcile.

## Prevention
- Использовать обязательный smoke-test pod DNS + HTTPS до bootstrap Flux.
- Не смешивать legacy CNI артефакты между переустановками.
- Обновлять runbooks после каждого инцидента.
