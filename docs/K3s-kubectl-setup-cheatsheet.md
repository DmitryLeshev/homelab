# Шпаргалка: kubectl на ноутбуке → k3s на сервере (Ubuntu 24 + Flux + SOPS/AGE)

Дата: 2026-04-10

## Идея (как это работает)
- `kubectl` — **клиент**, запускается на ноутбуке.
- k3s — **серверный Kubernetes**, API доступен по `https://<server>:6443`.
- `kubeconfig` (файл) содержит адрес API + сертификаты/учётку.
- Команды вида `kubectl create secret ... --from-file=...`:
  - читают файл **на той машине, где запущен kubectl** (т.е. на ноутбуке),
  - отправляют данные в Kubernetes API,
  - в кластере появляется `Secret`,
  - Flux/SOPS читает Secret уже **внутри кластера**.

---

## 1) Установка kubectl (Ubuntu 24)
```bash
sudo apt update
sudo apt install -y kubectl
kubectl version --client
```

---

## 2) Получить kubeconfig с сервера k3s
k3s kubeconfig обычно тут:
- `/etc/rancher/k3s/k3s.yaml`

### Вариант A (scp)
```bash
mkdir -p ~/.kube
scp user@SERVER:/etc/rancher/k3s/k3s.yaml ~/.kube/k3s.yaml
```

### Вариант B (через ssh + sudo cat)
```bash
mkdir -p ~/.kube
ssh user@SERVER 'sudo cat /etc/rancher/k3s/k3s.yaml' > ~/.kube/k3s.yaml
chmod 600 ~/.kube/k3s.yaml
```

> Примечание: нужен доступ `sudo` на сервере, иначе файл может быть недоступен.

---

## 3) Исправить адрес API-сервера в kubeconfig
Часто внутри kubeconfig стоит:
- `server: https://127.0.0.1:6443`  
Это “локалхост” **с точки зрения сервера**, а не ноутбука — надо заменить на IP/hostname сервера.

Проверить текущее значение:
```bash
grep -n "server:" ~/.kube/k3s.yaml
```

Заменить `127.0.0.1` на реальный адрес (пример):
```bash
sed -i 's/127.0.0.1/192.168.1.10/' ~/.kube/k3s.yaml
```

Если у вас hostname:
```bash
sed -i 's/127.0.0.1/k3s.myhome.lan/' ~/.kube/k3s.yaml
```

---

## 4) Подключить kubeconfig (выбрать контекст)

### Вариант A (быстро, на текущую сессию)
```bash
export KUBECONFIG=~/.kube/k3s.yaml
kubectl get nodes
```

### Вариант B (сделать по умолчанию навсегда)
```bash
echo 'export KUBECONFIG=~/.kube/k3s.yaml' >> ~/.bashrc
source ~/.bashrc
---
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> ~/.bashrc
source ~/.bashrc
```

### Вариант C (слить в стандартный ~/.kube/config)
Если вы хотите хранить несколько кластеров/контекстов вместе:
```bash
mkdir -p ~/.kube
touch ~/.kube/config

KUBECONFIG=~/.kube/config:~/.kube/k3s.yaml kubectl config view --flatten > /tmp/merged-kubeconfig
mv /tmp/merged-kubeconfig ~/.kube/config
chmod 600 ~/.kube/config

unset KUBECONFIG
kubectl config get-contexts
```

---

## 5) Проверки, что всё работает
```bash
kubectl config current-context
kubectl cluster-info
kubectl get nodes
kubectl get ns
kubectl -n flux-system get pods
```

---

## 6) Передать AGE ключ (SOPS) в кластер как Secret (Flux)
Создать или обновить (идемпотентно):
```bash
kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey="$HOME/.config/sops/age/keys.txt" \
  --dry-run=client -o yaml | kubectl apply -f -
```

Проверить, что Secret есть:
```bash
kubectl -n flux-system get secret sops-age
kubectl -n flux-system describe secret sops-age
```

---

## 7) Частые проблемы и быстрые решения

### 7.1) `kubectl: command not found`
Установить kubectl (см. раздел 1).

### 7.2) `Unable to connect to the server: ...`
Причины:
- неверный `server:` в kubeconfig (ещё `127.0.0.1`)
- порт 6443 недоступен с ноутбука (фаервол/роутинг)
- неверный IP/hostname

Проверка доступности порта:
```bash
nc -vz SERVER 6443
```

### 7.3) TLS/сертификат ругается
Чаще всего:
- подключаетесь не к тому адресу/домену (несовпадение SAN),
- или используете не тот kubeconfig.

Лучше использовать IP/hostname, который реально прописан/доступен, и не менять лишнее в kubeconfig кроме `server:`.

### 7.4) Права доступа (RBAC)
Если `kubectl get nodes` выдаёт `forbidden`, значит учётка из kubeconfig не имеет прав.
Решение зависит от того, как настроен доступ (обычно kubeconfig k3s даёт admin-доступ, но не всегда).

---

## 8) Мини-шаблон: переменные (заполнить)
- SERVER = `<ip или hostname>`
- user = `<ssh user>`
- kubeconfig path = `~/.kube/k3s.yaml`
- age key path = `~/.config/sops/age/keys.txt`