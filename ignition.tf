// provisioning_ssh_key creates a SSH key that will be used by the
// provisioners for each virtual machine to connect over SSH. This is a "fire
// and forget" key, and is deleted on the final step of the provisioner.
resource "tls_private_key" "provisioning_ssh_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

// root_user creates the user snippet for the "root" user for the
// virtual machine Ignition configuration. This allows us to push our
// provisioning key to the server.
data "ignition_user" "root_user" {
  name                = "root"
  ssh_authorized_keys = ["${tls_private_key.example_provisioning_ssh_key.public_key_openssh}"]
}

// example_core_user creates the user snippet for the "core" user for the
// virtual machine Ignition configuration. This is used to manage SSH keys for
// humans to connect to the virtual machines and manage them.
data "ignition_user" "core_user" {
  name                = "core"
  ssh_authorized_keys = ["${var.management_ssh_keys}"]
}


// virtual_machine_network_content renders a template with the systemd-networkd unit
// content for a specific virtual machine.
data "template_file" "virtual_machine_network_content" {
  count    = "${var.virtual_machine_count}"
  template = "${file("${path.module}/files/00-ens192.network.tpl")}"

  vars = {
    address = "${cidrhost(var.virtual_machine_network_address, var.virtual_machine_ip_address_start + count.index)}"
    mask    = "${element(split("/", var.virtual_machine_network_address), 1)}"
    gateway = "${var.virtual_machine_gateway}"
    dns     = "${join("\n", formatlist("DNS=%s", var.virtual_machine_dns_servers))}"
  }
}

// virtual_machine_network_unit defines the systemd network units for
// each virtual machine.
data "ignition_networkd_unit" "virtual_machine_network_unit" {
  count   = "${var.virtual_machine_count}"
  name    = "00-ens192.network"
  content = "${data.template_file.example_virtual_machine_network_content.*.rendered[count.index]}"
}

// virtual_machine_hostname_file defines the content of the system
// hostname file, in other words, it sets the hostname.
data "ignition_file" "virtual_machine_hostname_file" {
  count      = "${var.virtual_machine_count}"
  filesystem = "root"
  path       = "/etc/hostname"
  mode       = "420"

  content {
    content = "${var.virtual_machine_name_prefix}${count.index}.${var.virtual_machine_domain}"
  }
}

// ignition_config creates the CoreOS Ignition config for use on the
// virtual machines.
data "ignition_config" "ignition_config" {
  count    = "${var.virtual_machine_count}"
  files    = ["${data.ignition_file.virtual_machine_hostname_file.*.id[count.index]}"]
  systemd  = ["${data.ignition_systemd_unit.service_unit.id}"]
  networkd = ["${data.ignition_networkd_unit.virtual_machine_network_unit.*.id[count.index]}"]

  users = [
    "${data.ignition_user.root_user.id}",
    "${data.ignition_user.core_user.id}",
  ]

}
