variable vcenter_user {}
variable vcenter_password {}
variable vcenter_server {}
variable vcenter_dc {}
variable vcenter_rp {}
variable esxi_ip {}
variable mgmt_nw {}
variable guestinfo_hostname {}
variable guestinfo_interface_0_ip_0_address {}
variable guestinfo_interface_0_route_0_gateway {}
variable guestinfo_ves_clustername {}
variable guestinfo_ves_token {}
variable guestinfo_ves_certifiedhardware {}
variable guestinfo_ves_latitude {}
variable guestinfo_ves_longitude {}

provider "vsphere" {
  user                 = var.vcenter_user
  password             = var.vcenter_password
  vsphere_server       = var.vcenter_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.vcenter_dc
}

data "vsphere_datastore" "datastore" {
  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.vcenter_rp
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "esxi" {
  name          = var.esxi_ip
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.mgmt_nw
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "volterra-template"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  name             = var.guestinfo_ves_clustername
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 4
  memory           = 16384
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  scsi_type        = data.vsphere_virtual_machine.template.scsi_type
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }
  disk {
    label            = "disk0"
    size             = 40
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
  vapp {
    properties = {
      "guestinfo.hostname"                        = var.guestinfo_hostname
      "guestinfo.interface.0.name"                = "eth0"
      "guestinfo.interface.0.dhcp"                = "no"
      "guestinfo.interface.0.role"                = "public"
      "guestinfo.interface.0.ip.0.address"        = var.guestinfo_interface_0_ip_0_address
      "guestinfo.interface.0.route.0.destination" = "0.0.0.0/0"
      "guestinfo.interface.0.route.0.gateway"     = var.guestinfo_interface_0_route_0_gateway
      "guestinfo.ves.clustername"                 = var.guestinfo_ves_clustername
      "guestinfo.ves.token"                       = var.guestinfo_ves_token
      "guestinfo.ves.certifiedhardware"           = var.guestinfo_ves_certifiedhardware
      "guestinfo.ves.latitude"                    = var.guestinfo_ves_latitude
      "guestinfo.ves.longitude"                   = var.guestinfo_ves_longitude
      "guestinfo.ves.regurl"                      = "ves.volterra.io"
    }
  }
}