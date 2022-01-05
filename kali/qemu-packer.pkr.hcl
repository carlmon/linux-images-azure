variables {
   iso_url = ""
   iso_checksum = ""
   disk_size = "63G"
}

source "qemu" "kali" {
  iso_url           = var.iso_url
  iso_checksum      = var.iso_checksum
  output_directory  = "build"
  shutdown_command  = "shutdown -P now 'packer'"
  disk_size         = var.disk_size
  cpus              = 2
  memory            = 2048
  accelerator       = "kvm" # Needs to be supported by the host
  format            = "raw"
  headless          = true
  vm_name           = "image.raw"
  net_device        = "virtio-net"
  http_directory    = "preseed"
  communicator      = "ssh"
  ssh_username      = "root"
  ssh_password      = "temp-insecure" # Password cleared by deprovision
  ssh_timeout       = "20m"
  disk_interface    = "ide"
  boot_wait         = "-1s"
  boot_command      = [
    "<esc><wait3s>",
    "/install.amd/vmlinuz net.ifnames=0 ",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/automate.cfg ",
    "auto=true priority=critical vga=788 ",
    "initrd=/install.amd/initrd.gz --- quiet",
    "<wait3s><enter>",
    "<wait9m>" # main install step
  ]
}

build {
  provisioner "shell" {
    script = "./configure-kali.sh"
  }

  sources = ["source.qemu.kali"]
}
