output "vm_network_map" {
  value = {
    for key, vm in var.vms : key => {
      name        = vm.name
      mac_address = lower(vm.mac_address)
      vlan_tag    = vm.vlan_tag
    }
  }
}