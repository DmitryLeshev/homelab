# Install K3s With Cilium

## Purpose
Установить K3s без flannel и поднять рабочий Cilium dataplane.

## Context
Подходит для clean install на новых/очищенных VM. Используется как базовый bootstrap перед Flux.

## Steps
1. Очистить старый K3s/CNI на всех нодах.
```bash
sudo /usr/local/bin/k3s-killall.sh || true
sudo /usr/local/bin/k3s-uninstall.sh || true
sudo /usr/local/bin/k3s-agent-uninstall.sh || true
sudo rm -rf /etc/cni/net.d /var/lib/cni /var/lib/kubelet /var/lib/rancher/k3s
sudo ip link delete cilium_host 2>/dev/null || true
sudo ip link delete cilium_net 2>/dev/null || true
sudo ip link delete cilium_vxlan 2>/dev/null || true
```
2. Установить `server-1`.
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
3. Подключить остальные ноды.
```bash
export K3S_TOKEN="<TOKEN_FROM_SERVER1>"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
  --server https://10.10.30.14:6443 \
  --token ${K3S_TOKEN} \
  --flannel-backend=none \
  --disable-network-policy \
  --disable=traefik \
  --disable=servicelb" sh -

curl -sfL https://get.k3s.io | K3S_URL="https://10.10.30.14:6443" K3S_TOKEN="${K3S_TOKEN}" sh -
```
4. Настроить kubeconfig на server-1.
```bash
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> ~/.bashrc
source ~/.bashrc
kubectl get nodes -o wide
```
5. Установить Cilium.
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

## Validation
```bash
kubectl -n kube-system get pods -l k8s-app=cilium -o wide
kubectl get nodes
kubectl run smoke --rm -i --restart=Never --image=curlimages/curl:8.12.1 -- \
  sh -lc 'nslookup kubernetes.default.svc.cluster.local 10.43.0.10; curl -I --max-time 10 https://github.com'
```

## Pitfalls
- Пропустить очистку старых CNI артефактов.
- Смешать ручные `helm --set` и значения в Git.
- Начать Flux bootstrap до проверки pod egress.

## Rollback
1. Удалить Cilium и очистить CNI артефакты.
2. Повторить install steps с корректными параметрами.
