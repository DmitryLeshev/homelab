## Network Model

VMs use `ipconfig0 = "ip=dhcp"` and receive IPv4 settings from OPNsense DHCP.

Source of truth is split explicitly:

- Terraform owns VM lifecycle and the NIC MAC address.
- OPNsense owns DHCP reservations and therefore the actual IPv4 address.

This means `ip`, `cidr`, `gateway`, and `dns` are intentionally not stored in `variables.tf` anymore, because they are not applied by Terraform in the current design.

## Why MAC Is Pinned

DHCP static mappings depend on MAC address. If a VM is recreated and Proxmox generates a new MAC, OPNsense will stop giving it the expected IP.

To avoid that drift, each VM now has an explicit `mac_address` in `terraform.tfvars`, and Terraform passes it to Proxmox.

## Current Reservations

Reservations for the k3s nodes are currently expected to exist in OPNsense:

| Hostname | MAC address | Reserved IP |
| --- | --- | --- |
| k3s-server-1 | bc:24:11:56:9e:13 | 10.10.30.11 |
| k3s-server-2 | bc:24:11:72:34:63 | 10.10.30.12 |
| k3s-server-3 | bc:24:11:d8:7b:1d | 10.10.30.13 |
| k3s-agent-1 | bc:24:11:56:9f:db | 10.10.30.21 |
| k3s-agent-2 | bc:24:11:c0:43:a8 | 10.10.30.22 |
| k3s-agent-3 | bc:24:11:2b:f1:c0 | 10.10.30.23 |

If a reservation changes in OPNsense, update this table and keep the Terraform `mac_address` unchanged unless there is a deliberate NIC migration.

## Pitfalls

- Recreate risk: if a VM is deleted and recreated with another MAC, the reservation breaks. Pinning `mac_address` in Terraform removes the main failure mode.
- Split-brain inventory: Terraform no longer knows the reserved IPs. The documentation and OPNsense must stay aligned manually.
- Bootstrap dependency: first boot depends on DHCP being available and the reservation already existing in OPNsense.
- DNS and gateway drift: those settings now come from DHCP options, not cloud-init. If OPNsense options change, all VMs inherit the change.
- Rebuild timing: some services may come up before DHCP or DNS is ready after a cold boot; this is usually transient but worth remembering for cluster bootstrap.
- Bridge/VLAN consistency: `vlan_tag` still exists in variables, but the NIC tag is not applied in Terraform. If you expect VLAN tagging from Proxmox, enable that change deliberately and validate the plan separately.

## Operational Rule

When adding a new VM:

1. Reserve the IP in OPNsense for the planned MAC address.
2. Add the same `mac_address` to Terraform.
3. Apply Terraform.
4. Verify the lease and hostname in OPNsense after first boot.
