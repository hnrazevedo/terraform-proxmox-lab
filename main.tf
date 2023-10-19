variable "pm_api_url" {}
variable "pm_auth_user" {}
variable "pm_auth_password" {}
variable "pm_log_enable" {}
variable "pm_log_file" {}
variable "pm_debug" {}
variable "num_vm_instances" {}

terraform {
    required_providers {
        proxmox = {
            source  = "telmate/proxmox"
            version = "2.9.14"
        }
    }
}

provider "proxmox" {
    pm_api_url    = var.pm_api_url
    pm_user       = var.pm_auth_user
    pm_password   = var.pm_auth_password

    pm_log_enable = var.pm_log_enable
    pm_log_file   = var.pm_log_file
    pm_debug      = var.pm_debug
    pm_log_levels = {
        _default    = "debug"
        _capturelog = ""
    }
}

resource "proxmox_vm_qemu" "cluster" {
    count = var.num_vm_instances

    os_type     = "cloud-init"
    name        = "node-${count.index}"
    target_node = "pve"

    ipconfig0   = "ip=192.168.100.20${count.index}/24,gw=192.168.100.1"

    clone       = "debian-12-cloud-init"
    full_clone  = true

}