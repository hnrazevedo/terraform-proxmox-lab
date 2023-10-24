variable "pm_api_url" {}
variable "pm_auth_user" {}
variable "pm_auth_password" {}
variable "pm_log_enable" {}
variable "pm_log_file" {}
variable "pm_debug" {}
variable "masters_instances" {}
variable "nodes_instances" {}

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

resource "proxmox_vm_qemu" "masters" {
    count = var.masters_instances

    os_type     = "cloud-init"
    memory      = 6144
    cores       = 3
    sockets     = 2
    name        = "master-${count.index}"
    target_node = "pve"
    clone       = "debian-cloud"
    full_clone  = true
    ipconfig0   = "ip=192.168.100.10${count.index}/24,gw=192.168.100.1"
}

resource "proxmox_vm_qemu" "nodes" {
    count = var.nodes_instances

    os_type     = "cloud-init"
    memory      = 6144
    cores       = 3
    sockets     = 2
    name        = "node-${count.index}"
    target_node = "pve"
    clone       = "debian-cloud"
    full_clone  = true
    ipconfig0   = "ip=192.168.100.20${count.index}/24,gw=192.168.100.1"
}