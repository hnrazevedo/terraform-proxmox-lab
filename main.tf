variable "pm_api_url" {}
variable "pm_auth_user" {}
variable "pm_auth_password" {}
variable "pm_log_enable" {}
variable "pm_log_file" {}
variable "pm_debug" {}
variable "master_instances" {}
variable "master_cores" {}
variable "master_cpus" {}
variable "master_memory" {}
variable "master_pvehost" {}
variable "worker_instances" {}
variable "worker_cores" {}
variable "worker_cpus" {}
variable "worker_memory" {}
variable "worker_pvehost" {}

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
    count = var.master_instances

    os_type     = "cloud-init"
    memory      = var.master_memory
    cores       = var.master_cores
    sockets     = var.master_cpus
    name        = "master-${count.index}"
    target_node = var.master_pvehost
    clone       = "debian-cloud"
    full_clone  = true
    ipconfig0   = "ip=192.168.100.10${count.index}/24,gw=192.168.100.1"
}

resource "proxmox_vm_qemu" "nodes" {
    count = var.worker_instances

    os_type     = "cloud-init"
    memory      = var.worker_memory
    cores       = var.worker_cores
    sockets     = var.worker_cpus
    name        = "worker-${count.index}"
    target_node = var.worker_pvehost
    clone       = "debian-cloud"
    full_clone  = true
    ipconfig0   = "ip=192.168.100.20${count.index}/24,gw=192.168.100.1"
}