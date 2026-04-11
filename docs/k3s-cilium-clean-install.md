# K3s + Cilium Clean Install (Runbook)

Цель: установить k3s без flannel и поднять Cilium в рабочем режиме до bootstrap Flux.

## 0. Предпосылки
- Control-plane IP: `10.10.30.14`
- ОС: Ubuntu 24.04
- Выполнять команды на каждой VM локально.

## 1. Полная очистка старой установки (все ноды)
```bash
sudo /usr/local/bin/k3s-killall.sh || true
sudo /usr/local/bin/k3s-uninstall.sh || true
sudo /usr/local/bin/k3s-agent-uninstall.sh || true

sudo rm -rf /etc/cni/net.d /var/lib/cni /var/lib/kubelet /var/lib/rancher/k3s
sudo ip link delete cilium_host 2>/dev/null || true
sudo ip link delete cilium_net 2>/dev/null || true
sudo ip link delete cilium_vxlan 2>/dev/null || true
```

## 2. Установка server-1
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
  --cluster-init \
  --tls-san 10.10.30.14 \
  --flannel-backend=none \
  --disable-network-policy \
  --disable=traefik \
  --disable=servicelb \
  --write-kubeconfig-mode=644" sh -

sudo cat /var/lib/rancher/k3s/server/token
```

## 3. Установка остальных нод

### 3.1 Дополнительный server (если нужен)
```bash
export K3S_TOKEN="<TOKEN_FROM_SERVER1>"

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
  --server https://10.10.30.14:6443 \
  --token ${K3S_TOKEN} \
  --flannel-backend=none \
  --disable-network-policy \
  --disable=traefik \
  --disable=servicelb" sh -
```

### 3.2 Agent
```bash
export K3S_TOKEN="<TOKEN_FROM_SERVER1>"

curl -sfL https://get.k3s.io | K3S_URL="https://10.10.30.14:6443" K3S_TOKEN="${K3S_TOKEN}" sh -
```

## 4. kubeconfig на server-1
```bash
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> ~/.bashrc
source ~/.bashrc
kubectl get nodes -o wide
```

## 5. Cilium bootstrap через Helm
```bash
helm repo add cilium https://helm.cilium.io
helm repo update

helm upgrade --install cilium cilium/cilium \
  --namespace kube-system \
  --create-namespace \
  --version 1.17.14 \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=10.10.30.14 \
  --set k8sServicePort=6443 \
  --set ipam.mode=kubernetes \
  --set bpf.masquerade=true \
  --set enableIPv4Masquerade=true \
  --set routingMode=tunnel \
  --set tunnelProtocol=vxlan \
  --wait
```

## 6. Проверка сети до Flux (обязательно)
```bash
kubectl -n kube-system get pods -l k8s-app=cilium -o wide
kubectl get nodes -o wide

kubectl run netcheck --rm -i --restart=Never --image=curlimages/curl:8.12.1 -- \
  sh -lc 'nslookup github.com 10.43.0.10; curl -I --max-time 15 https://github.com'
```

Если этот шаг не проходит, bootstrap Flux не начинать.

## 6.1 Smoke test за 60 секунд
```bash
kubectl get nodes
kubectl -n kube-system get pods -l k8s-app=cilium
kubectl get svc kubernetes
kubectl run smoke --rm -i --restart=Never --image=curlimages/curl:8.12.1 -- \
  sh -lc 'nslookup kubernetes.default.svc.cluster.local 10.43.0.10; curl -I --max-time 10 https://github.com'
```

Ожидаемо:
- все ноды `Ready`
- cilium pod на каждой ноде `Running`
- DNS lookup успешный
- HTTPS до GitHub из pod успешный

## 7. Bootstrap Flux
```bash
export GITHUB_TOKEN="<VALID_GITHUB_PAT>"

flux bootstrap github \
  --owner=DmitryLeshev \
  --repository=homelab \
  --branch=main \
  --path=clusters/prod \
  --personal \
  --token-auth
```

## 8. SOPS age secret (если используется decryption)
```bash
kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey="$HOME/.config/sops/age/keys.txt" \
  --dry-run=client -o yaml | kubectl apply -f -
```

## 9. Reconcile и финальная проверка
```bash
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization flux-system -n flux-system --with-source

flux get sources git -A
flux get kustomizations -A
flux get helmreleases -A
```

## 10. Быстрый troubleshooting

### 10.1 Flux GitRepository timeout до GitHub
Проверить из pod:
```bash
kubectl run netcheck --rm -i --restart=Never --image=curlimages/curl:8.12.1 -- \
  sh -lc 'curl -I --max-time 15 https://github.com'
```

### 10.2 DNS в pod не работает
```bash
kubectl -n kube-system logs deploy/coredns --tail=200
kubectl -n kube-system get svc,endpoints kube-dns
```

### 10.3 Проверка Cilium
```bash
kubectl -n kube-system exec ds/cilium -- cilium status
```

## 11. Восстановление после аварии (3+3 команды)

Если после перезапуска нод/сети часть ресурсов в `NotReady`, выполни:

### 11.1 Три команды reconcile
```bash
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization infra-cilium -n flux-system --with-source
flux reconcile kustomization flux-system -n flux-system --with-source
```

### 11.2 Три команды проверки
```bash
flux get sources git -A
flux get kustomizations -A
flux get helmreleases -A
```

### 11.3 Если застрял `infra-cert-manager`
```bash
kubectl -n flux-system get secret sops-age
flux reconcile kustomization infra-cert-manager -n flux-system --with-source
flux reconcile kustomization infra-cert-manager-config -n flux-system --with-source
```
