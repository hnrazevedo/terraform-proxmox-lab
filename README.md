# terraform-proxmox-lab
Laboratório para criação de cluster em um ambiente de virtualização com Proxmox utilizando IaC

## Preparando ambiente Proxmox para o Terraform

Crie um usuário que será utilizado no Terraform para autênticação no servidor Proxmox
```sh
# useradd -s /dev/null -d /dev/null -p pve terraform-prov@pve
```
Crie e atribua a função `TerraformProv` ao usuário criado
```sh
# pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.use"
# pveum user add terraform-prov@pve --password <password>
# pveum aclmod / -user terraform-prov@pve -role TerraformProv
```

## Preparando Template para nodes

No servidor PVE, baixe uma imagem cloud da distribuição desejada, exemplo Debian e configure uma VM para gerar o Template
```sh
# cd /tmp
# wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
# apt install libguestfs-tools -y
# virt-customize --add debian-12-generic-amd64.qcow2 --install qemu-guest-agent
# qm create 9000 --name debian-cloud --ostype l26 --cpu cputype=host --net0 virtio,bridge=vmbr0
# qm set 9000 --scsi0 local-lvm:0,import-from=/tmp/debian-12-generic-amd64.qcow2 local-lvm
# rm -rf debian-12-generic-amd64.qcow2
# qm set 9000 --ide2 local-lvm:cloudinit
# qm set 9000 --boot c --bootdisk scsi0
# qm set 9000 --serial0 socket --vga serial0
# qm set 9000 --agent enabled=1
# qm disk resize 9000 scsi0 +100G
# qm template 9000
```

Defina um usuário e senha para autênticação e configure a chave SSH da máquina host no Cloud-init do template criado no Proxmox
```sh
# qm set 9000 --ciuser debian
# qm set 9000 --cipassword debian
# qm set 9000 --sshkey ~/.ssh/id_rsa.pub
```

## Autênticação no Terraform

Copie o arquivo .env.example para .env
```sh
# cp .env.example .env
```
Configure o endereço da api do servidor Proxmox, usuário e senha para autênticação, opções de logs e defina a configuração de hardware para os nodes masters e workers e em qual host do Proxmox cada node deve ser criado.
```sh
pm_api_url=https://proxmox-server01.example.com/api2/json
pm_auth_user=terraform-prov@pve
pm_auth_password=pve
pm_log_enable=true
pm_log_file=terraform-plugin-proxmox.log
pm_debug=true

master_instances=3
master_memory=6144
master_cpus=4
master_cores=1
master_pvehost="pve"

worker_instances=3
worker_memory=6144
worker_cpus=1
worker_cores=4
worker_pvehost="pve"
```

## Provisionando ambiente com Terraform

Na máquina host, execute o terraform por meio de um container e realize a criação do ambiente apontando o arquivo de variáveis: 
```sh
# docker container run --rm -v $PWD:/app -w /app -it --entrypoint sh hashicorp/terraform:light
/app # terraform init
/app # terraform plan -var-file=.env
/app # terraform apply -var-file=.env -auto-approve
```

## Construindo Cluster Kubernetes com Ansible

Configure o usuário de autênticação dos nodes, os endereços IP dos Masters e Workers no arquivo de inventário que se encontra no subdiretório ansible.

Após inventário configurado, aplique o playbook para a criação do cluster:
```sh
# ansible-playbook -i hosts site.yml
```