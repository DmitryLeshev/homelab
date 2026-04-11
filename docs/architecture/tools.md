# Tools And Rationale

## Selected Stack
- K3s: lightweight Kubernetes distribution for homelab.
- Flux: GitOps synchronization and dependency orchestration.
- Helm/HelmRelease: lifecycle management for infra charts.
- Cilium: CNI dataplane and service networking.
- MetalLB: on-prem LoadBalancer IP allocation.
- Traefik: ingress controller.
- cert-manager: certificate lifecycle.
- SOPS + age: secret encryption at rest in Git.
- Terraform (Proxmox): VM provisioning outside cluster.

## Why These Tools
- K3s: low operational overhead for small clusters.
- Flux: native CRD model + clean reconciliation workflow.
- Cilium: flexible networking modes and strong observability.
- MetalLB: practical replacement for cloud LoadBalancer in bare metal setups.
- SOPS+age: simple secret workflow without external KMS dependency.

## Trade-offs
- Helm + Flux gives reusable packages but introduces controller dependency chain.
- Cilium advanced modes increase flexibility but require stricter network validation.
- SOPS avoids plain secrets in Git, but adds key lifecycle management burden.

## Alternatives Considered
- Argo CD instead of Flux: stronger UI but higher operational footprint.
- Flannel instead of Cilium: simpler default, lower feature set.
- External secret managers: stronger centralization, but more infra dependencies.
