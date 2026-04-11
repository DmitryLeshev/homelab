# Flux + SOPS + age — шпаргалка (Ubuntu 24.04 + k3s)

Дата: 2026-04-10

## Что где хранится (важно понимать)
- **Git репозиторий**: хранит *зашифрованные* YAML (SOPS).
- **Кластер Kubernetes**: хранит применённые `Secret` в виде `data:` (base64), **не SOPS**.
- **Flux** (в кластере): при наличии `spec.decryption` расшифровывает SOPS-файлы перед apply.
- **age private key**:
  - локально у тебя: `~/.config/sops/age/keys.txt`
  - в кластере: `Secret` `flux-system/sops-age` (чтобы Flux мог расшифровывать)

---

## Установка на Ubuntu 24.04 (машина, где шифруешь)

### age
```bash
sudo apt update
sudo apt -y install age
```

### sops (бинарник)
Для amd64/x86_64:
```bash
SOPS_VER=3.9.4
curl -fsSL -o /tmp/sops "https://github.com/getsops/sops/releases/download/v${SOPS_VER}/sops-v${SOPS_VER}.linux.amd64"
sudo install -m 0755 /tmp/sops /usr/local/bin/sops
rm -f /tmp/sops
sops --version
```

---

## Генерация age ключей
```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

Публичный ключ (для `.sops.yaml`):
```bash
age-keygen -y ~/.config/sops/age/keys.txt
```

Переменная окружения (опционально):
```bash
echo 'export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"' >> ~/.bashrc
source ~/.bashrc
```

---

## Добавить age private key в кластер (для Flux)
```bash
kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey="$HOME/.config/sops/age/keys.txt"
```

Проверка:
```bash
kubectl -n flux-system get secret sops-age
```

---

## Включить расшифровку SOPS в Flux (обязательно)
В репозитории в объекте `Kustomization` (например `clusters/prod/flux-system/gotk-sync.yaml`) добавь:

```yaml
spec:
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

После push:
```bash
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization flux-system -n flux-system --with-source
```

---

## `.sops.yaml` (в корень репозитория)
Пример: шифровать файлы `*.secret.yaml`, шифровать только `data`/`stringData`:

```yaml
creation_rules:
  - path_regex: '.*\.secret\.ya?ml$'
    encrypted_regex: '^(data|stringData)$'
    age: 'age1PASTE_YOUR_PUBLIC_KEY_HERE'
```

---

## Создать Secret и зашифровать

### Пример файла
`apps/myapp/myapp.secret.yaml`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secret
  namespace: default
type: Opaque
stringData:
  username: admin
  password: supersecret
```

### Зашифровать inplace
```bash
sops --encrypt --in-place clusters/prod/infra/cert-manager/cloudflare-api-token.secret.yaml
```

### Редактировать зашифрованный файл
```bash
sops apps/myapp/myapp.secret.yaml
```

---

## Kustomize структура (пример)

`apps/myapp/kustomization.yaml`:
```yaml
resources:
  - myapp.secret.yaml
```

`clusters/prod/flux-system/kustomization.yaml`:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
  - ../../../apps/myapp
```

---

## Проверки и диагностика Flux

### Статус контроллеров
```bash
kubectl -n flux-system get pods
```

### Источники Git
```bash
flux get sources git -A
kubectl -n flux-system get gitrepositories.source.toolkit.fluxcd.io
```

### Kustomizations
```bash
flux get kustomizations -A
kubectl -n flux-system get kustomizations.kustomize.toolkit.fluxcd.io
```

### Принудительно пересинхронизировать
```bash
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization flux-system -n flux-system --with-source
```

### События
```bash
kubectl -n flux-system get events --sort-by=.lastTimestamp | tail -n 50
kubectl -n default get events --sort-by=.lastTimestamp | tail -n 80
```

### Логи kustomize-controller
```bash
kubectl -n flux-system logs deploy/kustomize-controller --since=2h | tail -n 200
```

---

## Проверка Secret в кластере

### Посмотреть yaml (data в base64)
```bash
kubectl -n default get secret myapp-secret -o yaml
```

### Декодировать конкретное поле
```bash
kubectl -n default get secret myapp-secret -o jsonpath='{.data.username}' | base64 -d; echo
kubectl -n default get secret myapp-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

### Показать все ключи (нужен jq)
```bash
kubectl -n default get secret myapp-secret -o json \
  | jq -r '.data | to_entries[] | "\(.key)=\(.value|@base64d)"'
```

---

## Памятка по безопасности
- Приватный age ключ **нельзя** коммитить в Git.
- `Secret` `flux-system/sops-age` — критичный; ограничь доступ (RBAC).
- В Kubernetes `Secret` — это base64, а не шифрование: доступ к API = доступ к секретам.