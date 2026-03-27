# TP2 : Azure first steps

## 2. Une paire de clés SSH

**🌞 Déterminer quel algorithme de chiffrement utiliser pour vos clés**

* **Pourquoi éviter RSA pour SSH ?**
    > RSA est de moins en moins recommandé à mesure que la technologie progresse et que de plus grandes clés (supérieures à 2048 bits) sont nécessaires, incitant à considérer des algorithmes alternatifs.
    * *Source d'information :* [Comparing SSH Key Algorithms (strongdm.com)](https://www.strongdm.com/blog/comparing-ssh-keys#:~:text=Types%20of%20SSH%20Key%20Algorithms,-RSA&text=However%2C%20as%20technology%20advances%2C%20larger,requiring%20consideration%20of%20alternative%20algorithms.)

* **Algorithme de chiffrement recommandé : ED25519**
    > **ED25519** est l'algorithme recommandé pour les nouvelles clés SSH.
    * *Source de recommandation :* [SSH Keys and Best Practices (docs.cis.strath.ac.uk)](https://docs.cis.strath.ac.uk/ssh-keys/#:~:text=ssh%5Cid_ed25519%20on%20Windows).,should%20consider%20upgrading%20where%20possible.)

### B. Génération de votre paire de clés 🛠️

**🌞 Générer une paire de clés pour ce TP**

la clé privée doit s'appeler `cloud_tp1` :
* elle doit se situer dans le dossier standard pour votre utilisateur
* elle doit utiliser l'algorithme que vous avez choisi à l'étape précédente (donc, pas de RSA)
* elle est protégée par un mot de passe de votre choix

```bash
ssh-keygen -t ed25519 -f ~/.ssh/cloud_tp1
```

**🌞 Configurer un agent SSH sur votre poste**

détaillez-moi toute la conf ici que vous aurez fait :

```bash
systemctl --user enable --now ssh-agent
ssh-add ~/.ssh/cloud_tp1
```

---

## II. Spawn des VMs

### 1. Depuis la WebUI

**🌞 Connectez-vous en SSH à la VM pour preuve**

cette connexion ne doit demander aucun password : votre clé a été ajoutée à votre Agent SSH

```text
cesaaar@fedora:~$ ssh azureuser@9.205.16.97
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.17.0-1008-azure x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Mon Mar 23 09:12:10 UTC 2026

  System load:  0.04              Processes:             115
  Usage of /:   5.7% of 28.02GB   Users logged in:       0
  Memory usage: 29%               IPv4 address for eth0: 10.0.0.4
  Swap usage:   0%
...
azureuser@vm2:~$ 
```

### 2. az : a programmatic approach

**🌞 Créez une VM depuis le Azure CLI**

en utilisant uniquement la commande `az` donc :

```bash
az vm create -g TP2 -n vmJ --size Standard_B1s --image almalinux:almalinux-x86_64:10-gen2:10.1.202512150 --admin-username cesaaar --ssh-key-values "ssh-ed25519 et puis ma clé en gros"
```

**🌞 Assurez-vous que vous pouvez vous connecter à la VM en SSH sur son IP publique**

une commande SSH fonctionnelle vers la VM sans password toujouuurs because Agent SSH

```text
cesaaar@fedora:~$ ssh cesaaar@9.205.155.240
The authenticity of host '9.205.155.240 (9.205.155.240)' can't be established.
ED25519 key fingerprint is SHA256:9AIQ9GRSPLmxcI+6QShluycOS8EeRixjryNMcwjGkkE.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '9.205.155.240' (ED25519) to the list of known hosts.
[cesaaar@vmJ ~]$ ip a
```

**🌞 Une fois connecté, prouvez la présence...**

...du service `waagent.service` :

```text
[cesaaar@vmJ ~]$ systemctl status waagent.service
● waagent.service - Azure Linux Agent
     Loaded: loaded (/usr/lib/systemd/system/waagent.service; enabled; preset: enabled)
     Active: active (running) since Mon 2026-03-23 09:49:07 UTC; 8min ago
   Main PID: 1323 (python3)
     CGroup: /azure.slice/waagent.service
             ├─1323 /usr/bin/python3 -u /usr/sbin/waagent -daemon
             └─1455 /usr/bin/python3 -u bin/WALinuxAgent-2.15.0.1-py3.12.egg -run-exthandlers
```

...du service `cloud-init.service` :

```text
[cesaaar@vmJ ~]$ systemctl status cloud-init.service
● cloud-init.service - Cloud-init: Network Stage
     Loaded: loaded (/usr/lib/systemd/system/cloud-init.service; enabled; preset: enabled)
     Active: active (exited) since Mon 2026-03-23 09:49:07 UTC; 9min ago
   Main PID: 945 (code=exited, status=0/SUCCESS)
```

### 3. Terraforming planets infrastructures

**🌞 Utilisez Terraform pour créer une VM dans Azure**

j'veux la suite de commande terraform utilisée dans le compte-rendu :

```text
cesaaar@fedora:~/Téléchargements/cours$ terraform init
Initializing the backend...
Initializing provider plugins...
- Reusing previous version of hashicorp/azurerm from the dependency lock file
- Using previously-installed hashicorp/azurerm v4.65.0

cesaaar@fedora:~/Téléchargements/cours$ terraform plan
# azurerm_linux_virtual_machine.main will be created
  + resource "azurerm_linux_virtual_machine" "main" {
      + admin_username = "cesaaar"

cesaaar@fedora:~/Téléchargements/cours$ terraform apply
# azurerm_linux_virtual_machine.main will be created
  + resource "azurerm_linux_virtual_machine" "main" {
```

**🌞 Prouvez avec une connexion SSH sur l'IP publique que la VM est up**

toujours pas de password avec votre Agent SSH normalement 🐈

```text
cesaaar@fedora:~/Téléchargements/cours$ ssh cesaaar@9.205.154.79
The authenticity of host '9.205.154.79 (9.205.154.79)' can't be established.
ED25519 key fingerprint is SHA256:VPcmWXAHQ7lLIWB5pWIY0e+aJzbTG6/vuVZViKCqDaA.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '9.205.154.79' (ED25519) to the list of known hosts.
[cesaaar@super-vm ~]$ 
```
