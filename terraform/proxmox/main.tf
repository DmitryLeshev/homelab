provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "vm" {
  for_each = var.vms

  name        = each.value.name
  vmid        = each.value.vmid
  target_node = var.target_node

  clone   = var.template_name
  os_type = "cloud-init"

  memory = each.value.memory_mb
  scsihw = "virtio-scsi-single" #   scsihw = "virtio-scsi-pci"
  boot   = "order=scsi0;net0"

  agent = 1

  cpu {
    type    = "x86-64-v2-AES"
    cores   = each.value.cores
    sockets = 2
  }

  # Cloud-init
  ciuser    = "ubuntu"
  ipconfig0 = "ip=dhcp"
  sshkeys   = var.ssh_public_keys


  network {
    id      = 0
    model   = "virtio"
    bridge  = var.vm_bridge
    macaddr = lower(each.value.mac_address)
    # tag    = each.value.vlan_tag
  }

  disks {
    scsi {
      scsi0 {
        disk {
          size    = "${each.value.disk_gb}G"
          storage = each.value.storage
        }
      }
    }
  }
}