# Access Model (RBAC)

## Access Layers
- Infrastructure access: SSH/Sudo к VM (K3s nodes).
- Cluster API access: `kubectl` через kubeconfig.
- GitOps access: Flux доступ к Git repository.
- Secrets access: age private key для SOPS decryption.

## Role Separation
- Platform admin:
  - управляет k3s/сетью/Flux bootstrap;
  - имеет доступ к `flux-system`, `kube-system`.
- Application operator:
  - управляет namespace приложений;
  - не изменяет сетевые и cluster-critical компоненты.

## Minimal Governance Rules
- Не коммитить private keys и plain secrets в Git.
- Secret `flux-system/sops-age` считать критичным активом.
- Разделять операции bootstrap и day-2 (runbooks).
- Все изменения инфраструктуры проводить через GitOps, а не kubectl apply напрямую.

## Known Sensitive Points
- Доступ к kubeconfig с cluster-admin правами.
- GitHub token для Flux bootstrap.
- age private key (`~/.config/sops/age/keys.txt`).
