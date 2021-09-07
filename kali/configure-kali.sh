#!/bin/bash
set -e

short_boot() {
    # Lower grub boot wait time to 1s
    sed -i -e "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/g" /etc/default/grub
    sed -i -e "s/timeout=5/timeout=1/g" /boot/grub/grub.cfg
}

dependencies() {
    export DEBIAN_FRONTEND=noninteractive
    apt update && apt dist-upgrade -y && \
    apt install -y python3-pip waagent cloud-init && \
    apt autoremove -y && apt clean -y
}

azure_agent() {
    # Configure agent to delegate provisioning to Cloud-Init
    sed -i "s/Provisioning.UseCloudInit=n/Provisioning.UseCloudInit=y/g" /etc/waagent.conf

    # Dirty workaround from https://github.com/Azure/WALinuxAgent/issues/1904
    sed -i "s/import DebianOSModernUtil/import DebianOSModernUtil, DebianOSBaseUtil/g" \
      /usr/lib/python3/dist-packages/azurelinuxagent/common/osutil/factory.py

    systemctl enable walinuxagent.service
}

cloud_init() {
    systemctl enable cloud-init-local.service
    systemctl enable cloud-init.service
    systemctl enable cloud-config.service
    systemctl enable cloud-final.service
}

deprovision() {
    # Deprovision the VM for Azure
    rm -f ~/.bash_history
    waagent -force -deprovision
}

short_boot
dependencies
azure_agent
cloud_init
deprovision

echo "All done!"