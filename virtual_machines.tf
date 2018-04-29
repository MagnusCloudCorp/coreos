// virtual_machines creates virtual machines
// host.
resource "vsphere_virtual_machine" "example_virtual_machines" {
  count            = "${virtual_machine_count}"
  name             = "${var.virtual_machine_name_prefix}${count.index}"
  resource_pool_id = "${data.vsphere_resource_pool.resource_pool.id}"
  # host_system_id   = "${data.vsphere_host.example_hosts.*.id[count.index]}"
  datastore_id     = "${data.vsphere_datastore.example_datastore.id}"

  num_cpus = 2
  memory   = 1024
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label = "disk0"
    size  = "${data.vsphere_virtual_machine.template.disks.0.size}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    linked_clone  = true
  }

  vapp {
    properties {
      "guestinfo.coreos.config.data" = "${data.ignition_config.ignition_config.*.rendered[count.index]}"
    }
  }
}
