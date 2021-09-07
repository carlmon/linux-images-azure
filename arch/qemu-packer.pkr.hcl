variables {
   iso_url = ""
   iso_checksum = ""
   disk_size = "63G"
}

source "qemu" "arch" {
  iso_url           = var.iso_url
  iso_checksum      = var.iso_checksum
  output_directory  = "build"
  shutdown_command  = "echo 'packer' | sudo -S shutdown -P now"
  disk_size         = var.disk_size
  cpus              = 2
  memory            = 2048
  accelerator       = "kvm" # Needs to be supported by the host
  format            = "raw"
  headless          = true
  vm_name           = "image.raw"
  net_device        = "virtio-net"
  communicator      = "ssh"
  ssh_username      = "root"
  ssh_password      = "temp-insecure" # Only used for the ISO boot session
  ssh_timeout       = "20m"
  disk_interface    = "ide"
  boot_wait         = "-1s"
  boot_command      = [
    "<enter><wait40s>",
    "echo 'root:temp-insecure' | chpasswd<enter><wait2s>"
  ]
}

build {
  provisioner "shell" {
    script = "./install-arch.sh"
  }

  sources = ["source.qemu.arch"]
}
