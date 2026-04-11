echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> ~/.bashrc
source ~/.bashrc

CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

cilium install \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=10.10.30.14 \
  --set k8sServicePort=6443

2) Я запустил на vm эти команды
```
k3s-server-1
curl -sfL https://get.k3s.io | K3S_TOKEN='l%TH]c4VvCT<Xj{' sh -s - server --cluster-init 
cat /var/lib/rancher/k3s/server/token
watch kubectl get nodes

k3s-server-(2-3)
curl -sfL https://get.k3s.io | K3S_TOKEN='l%TH]c4VvCT<Xj{' sh -s - server --server https://10.10.30.11:6443

k3s-agent-(1-3)
curl -sfL https://get.k3s.io | K3S_URL="https://10.10.30.11:6443" \
      K3S_TOKEN='K10be7a4123927b7062cdab4d8daaa038095366f58569ef56952a712c229c09a7e9::server:l%TH]c4VvCT<Xj{' \
      sh -
```
Но я хочу использовать Cilium через helm а не дефолтный flannel


---
Это второй тестовый k3s

curl -sfL https://get.k3s.io | sudo sh -s - server \
  --cluster-init \
  --tls-san 10.10.30.14 \
  --disable traefik \
  --flannel-backend=none \
  --disable-network-policy

cat /var/lib/rancher/k3s/server/token

curl -sfL https://get.k3s.io | sudo sh -s - agent \
  --server "https://10.10.30.14:6443" \
  --token "K10ba06b3230feb1d450f183be6ad45cd9e73c4e1cd305d21e4d42a6adb73041707::server:7170855e87cbd6bc462cdc6709ecf0ae"

export GITHUB_TOKEN=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
flux bootstrap github \
  --owner=DmitryLeshev \
  --repository=homelab \
  --branch=main \
  --path=clusters/prod \
  --personal
