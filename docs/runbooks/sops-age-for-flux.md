# Configure SOPS age For Flux

## Purpose
Настроить расшифровку SOPS-секретов в Flux через `flux-system/sops-age`.

## Context
Нужно для `Kustomization` с `spec.decryption.provider: sops`.

## Steps
1. Установить `age` и `sops` на машину, где шифруются манифесты.
2. Создать или использовать существующий age keypair.
```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
```
3. Создать или обновить Kubernetes secret.
```bash
kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey="$HOME/.config/sops/age/keys.txt" \
  --dry-run=client -o yaml | kubectl apply -f -
```
4. Проверить `spec.decryption` в соответствующей Flux Kustomization.

## Validation
```bash
kubectl -n flux-system get secret sops-age
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization flux-system -n flux-system --with-source
```

## Pitfalls
- Неправильный age private key (не совпадает с recipient в зашифрованных файлах).
- Секрет создан не в `flux-system`.
- Ключ случайно попал в Git.

## Rollback
1. Пересоздать `sops-age` с корректным ключом.
2. Повторить reconcile.
