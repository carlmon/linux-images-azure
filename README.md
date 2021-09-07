# Linux Azure Images
This project uses Azure Pipelines to create brand new image VHDs for Azure from ISOs through Packer. All image creation and deployment automation code is provided by the project.

## Overview

### Why?
Microsoft and Azure Marketplace publishers only provide a few Linux images for Azure. There are no Arch Linux images and the Kali image is [severely outdated](https://twitter.com/kalilinux/status/1379435479725051913?s=20)

### Why Azure?
Azure is a large cloud provider with first-class Linux support. While there are cheaper options for hobbyists, many developers and IT staff receive monthly Azure credits through MSDN for testing and development.

### Why Packer?
There are more efficient methods to create Linux images - or even to change a regular Azure Ubuntu VM into Arch or Kali. The Packer-from-ISO method was chosen for fun and educational purposes.

### Where are the images?
This project does **NOT** provide VM images to the general public. **Never use OS images from untrusted publishers.**

## Automation Process
1. Azure Pipelines triggers a build when I update the ISO version information in GitHub.
1. It first checks if the specified version already exists in my Shared Image Gallery. If it exists, the process ends.
2. If not, HashiCorp Packer downloads and installs the OS ISO in a QEMU VM.
3. The VM image is converted to VHD format for Azure and uploaded to my Blob Storage.
4. This image is tagged and replicated to specified regions in my Shared Image Gallery for easy deployment.

## Notes
* The VMs are pretty much standard installations with the addition of [Cloud-Init](https://cloud-init.io/) and [Microsoft Azure Linux Agent](https://github.com/Azure/WALinuxAgent)
* The Azure Pipelines build agents use Ubuntu 20.04 images in an [VM Scale Set](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops)
* The build VMs need a size that supports KVM for QEMU during the installation process with Packer. I use Azure's `D4s_v3`
* The Packer and setup Shell scripts do not rely on Azure Pipelines and can be used on other platforms, or locally

## To Do
* Migrate to UEFI-based boot and [Azure Gen2 VMs](https://docs.microsoft.com/en-us/azure/virtual-machines/generation-2#features-and-capabilities)
* Implement full disk encryption for VMs with [dm-crypt](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disk-encryption-overview)
* Auto-create swap with [cloud-init on Kali VM](https://wiki.ubuntu.com/AzureSwapPartitions). It works by default on Arch