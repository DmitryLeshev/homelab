
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
  --token "K10873a928f52e4c02b59d5dd159990133e5efd6262c637d5f2470552bf4455eed7::server:f737f392e6ca466afaef9ed92348268a"
