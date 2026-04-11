# Operational Commands Reference

## Kubernetes
```bash
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get ingress -A -o wide
kubectl -n <ns> describe <kind> <name>
kubectl get events -A --sort-by=.lastTimestamp | tail -n 80
```

## Flux
```bash
flux get sources git -A
flux get kustomizations -A
flux get helmreleases -A
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization flux-system -n flux-system --with-source
```

## Helm
```bash
helm repo add cilium https://helm.cilium.io
helm repo update
helm upgrade --install cilium cilium/cilium -n kube-system --version 1.17.14
helm ls -A
```

## Network Debug (Pods)
```bash
kubectl run netcheck --rm -i --restart=Never --image=curlimages/curl:8.12.1 -- \
  sh -lc 'nslookup github.com 10.43.0.10; curl -I --max-time 15 https://github.com'

kubectl -n kube-system logs deploy/coredns --tail=200
kubectl -n kube-system exec ds/cilium -- cilium status
```

## Linux/Systemd
```bash
systemctl cat k3s | sed -n '1,220p'
journalctl -u k3s -b | tail -n 200
ps -ef | grep '[k]3s server'
ip route
```

## SOPS/age
```bash
age-keygen -o ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey="$HOME/.config/sops/age/keys.txt" \
  --dry-run=client -o yaml | kubectl apply -f -
```
