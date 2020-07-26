# add the provider, this code will connect to Hypervisor using libvirt
provider "libvirt" {
  uri = "qemu:///system"
}

terraform {
  required_version = ">= 0.12"
}
 
# create private pool for this vm
resource "libvirt_pool" "ubuntu-node0" {
 name = "ubuntu-node0"
 type = "dir"
 path = "${path.module}/pool/ubuntu-node0"
}

# Create Network
resource "libvirt_network" "net-10_100_100" {
        name = "net-10_100_100"
        addresses = ["10.100.100.0/24"]
}
 
# create image volume vda
resource "libvirt_volume" "ubuntu-node0-vda" {
 name = "ubuntu-node0-vda.qcow2"
 pool = libvirt_pool.ubuntu-node0.name
 base_volume_name = "bionic-server-cloudimg-amd64.img"
 base_volume_pool = "images"
 format = "qcow2"
 size = "10737418240"
}

# create image volume vdb
#resource "libvirt_volume" "ubuntu-node0-vdb" {
# name = "ubuntu-node0-vdb.qcow2"
# pool = libvirt_pool.ubuntu-node0.name
# format = "qcow2"
# size = "10737418240"
#}
 
# add cloudinit disk to pool
resource "libvirt_cloudinit_disk" "ubuntu-node0-cloudinit" {
 name = "ubuntu-node0-cloudinit.iso"
 pool = libvirt_pool.ubuntu-node0.name
 user_data = data.template_file.user_data.rendered
 network_config = data.template_file.network_config.rendered
}
 
# read cloud_init configuration
data "template_file" "user_data" {
 template = file("${path.module}/cloud_init.cfg")
}

# read network_config configuration
data "template_file" "network_config" {
    template = file("${path.module}/network_config.cfg")
}
 
# Define KVM domain to create
resource "libvirt_domain" "ubuntu-node0" {
  name   = "ubuntu-node0"
  memory = "2048"
  vcpu   = "2"
  cloudinit = libvirt_cloudinit_disk.ubuntu-node0-cloudinit.id

  cpu = {
    mode = "host-passthrough"
  }
 
  network_interface {
    network_name = "net-10_100_100"
    addresses = ["10.100.100.10"]
  }

  disk {
    volume_id = libvirt_volume.ubuntu-node0-vda.id
  }  

  #disk {
  #  volume_id = libvirt_volume.ubuntu-1-vm-vdb.id
  #}
 
  console {
    type = "pty"
    target_port = "0"
    target_type = "serial"
  }
 
  graphics {
    type = "vnc"
    listen_type = "address"
     autoport = true
  }
}
