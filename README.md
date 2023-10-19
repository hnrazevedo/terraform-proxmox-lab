# terraform-proxmox-lab
Laboratório para criação de cluster em um ambiente de virtualização com Proxmox utilizando IaC

## Configuração Proxmox para o Terraform

Crie um usuário para autênticação no Terraform
```sh
# useradd -s /dev/null -d /dev/null -p pve terraform-prov@pve
```
Adicione a função TERRAFORM-PROV ao usuário terraform-prov
```sh
# pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.use"
# pveum user add terraform-prov@pve --password <password>
# pveum aclmod / -user terraform-prov@pve -role TerraformProv
```

## Configurando Template
No servidor PVE, baixe uma imagem cloud da distribuição desejada, exemplo Debian e configure uma VM para gerar o Template
```sh
# cd /tmp
# wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
# apt install libguestfs-tools -y
# virt-customize --add debian-12-generic-amd64.qcow2 --install qemu-guest-agent
# qm create 9001 --name debian-12-cloud-init --numa 0 --ostype l26 --cpu cputype=host --cores 3 --sockets 2 --memory 6144 --net0 virtio,bridge=vmbr0
# qm importdisk 9001 /tmp/debian-12-generic-amd64.qcow2 local-lvm
# qm set 9001 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9001-disk-0
# qm set 9001 --ide2 local-lvm:cloudinit
# qm set 9001 --boot c --bootdisk scsi0
# qm set 9001 --serial0 socket --vga serial0
# qm set 9001 --agent enabled=1
# qm disk resize 9001 scsi0 +100G
# qm template 9001
```


## Autênticação no Terraform

Copie o arquivo .env.example para .env
```sh
# cp .env.example .env
```
Configure o endereço do servidor Proxmox, parâmetros para autênticação e opções de logs.
```sh
pm_api_url=https://proxmox-server01.example.com/api2/json
pm_auth_user=terraform-prov@pve
pm_auth_password=pve
pm_log_enable=true
pm_log_file=terraform-plugin-proxmox.log
pm_debug=true
```

## Provisionando com Terraform
```sh
# docker container run --rm -v $PWD:/app -w /app -it --entrypoint sh hashicorp/terraform:light
# terraform init
# terraform plan -var-file=.env
# terraform apply -var-file=.env
```