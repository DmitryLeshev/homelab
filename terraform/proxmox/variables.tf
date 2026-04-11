variable "proxmox_api_url" {
  type        = string
  description = "URL API Proxmox, например https://proxmox.example.com:8006/api2/json"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "API token id в формате user@realm!tokenid, например root@pam!terraform"
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Секретный ключ API токена"
  sensitive   = true
}

variable "target_node" { type = string } # имя Proxmox node, напр. "pve"

variable "template_name" { type = string } # имя VM template с Ubuntu 24.04 cloud-init

variable "ssh_public_keys" {
  type        = string
  description = "SSH public keys (newline-separated) for cloud-init"
}

variable "vm_bridge" {
  type    = string
  default = "vmbr1"
}

variable "vms" {
  type = map(object({
    vmid        = number
    name        = string
    vlan_tag    = number
    mac_address = string # e.g. bc:24:11:56:9e:13
    cores       = number
    memory_mb   = number
    disk_gb     = number
    storage     = string # local-zfs / hdd-data / hdd-vmstore / etc
  }))

  validation {
    condition = length(distinct([
      for vm in values(var.vms) : lower(vm.mac_address)
    ])) == length(values(var.vms))
    error_message = "Each VM must have a unique mac_address."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) : can(regex("^([0-9a-f]{2}:){5}[0-9a-f]{2}$", lower(vm.mac_address)))
    ])
    error_message = "Each mac_address must use the format aa:bb:cc:dd:ee:ff."
  }
}