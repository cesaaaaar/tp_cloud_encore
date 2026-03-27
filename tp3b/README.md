# TP3B : Hardened base image

## TP3B Part 1 - Create the base VM

### 2. Feu patate

Dans cette partie on commence donc ez : on va juste créer la VM.

**🌞 Créez une VM Azure (une commande `az`)**

* Ça doit être un Alma Linux 10.
* Elle doit se baser sur cette image Azure.
* Vous devez pouvoir vous y connecter en SSH avec une de vos clés publiques existantes.

```bash
az vm create -g TP2 -n vmJ --size Standard_B1s --image almalinux:almalinux-x86_64:10-gen2:10.1.202512150 --admin-username cesaaar --ssh-key-values "ssh-ed25519 puis ma clé tavu"
```

**🌞 Connexion SSH**

Connectez-vous en SSH à la VM :

```bash
cesaaar@fedora:~/Téléchargements/cours$ ssh cesaaar@9.205.156.86
The authenticity of host '9.205.156.86 (9.205.156.86)' can't be established.
ED25519 key fingerprint is SHA256:BMwfaLQENzmkAP6FFsQfCXzQOxQVEWr8wmfz0pnf+Us.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '9.205.156.86' (ED25519) to the list of known hosts.
[cesaaar@vmJ ~]$ 
```

---

## TP3B Part 2 - Prepare the VM

### 1. Poser notre conf custom

**🌞 Effectuez la conf suivante :**

* Mettez le système à jour.
* Les commandes suivantes doivent être dispos : `htop`, `vim`, `dig`, `ping`.

```bash
[cesaaar@vmJ ~]$ sudo dnf update -y
[cesaaar@vmJ ~]$ sudo dnf install epel-release -y
[cesaaar@vmJ ~]$ sudo dnf install htop vim bind-utils iputils -y
```

Vérifications :
```bash
[cesaaar@vmJ ~]$ htop -h
htop 3.3.0
[cesaaar@vmJ ~]$ ping -h
Usage: ping [options] <destination>
[cesaaar@vmJ ~]$ vim -h
VIM - Vi IMproved 9.1 (2024 Jan 02, compiled Feb 25 2026 00:00:00)
[cesaaar@vmJ ~]$ dig -h
Usage:  dig [@global-server] [domain] [q-type] [q-class] {q-opt}
```

### 2. Clean la VM

**B. Clean le système**

**🌞 Proposer une suite de commandes**

* Ça clean les logs de la machine.
* Ça clean l'historique de commande.

```bash
[cesaaar@vmJ log]$ sudo rm btmp cron dnf.librepo.log dnf.log dnf.rpm.log hawkey.log lastlog messages secure spooler waagent.log wtmp tuned/tuned.log 
[cesaaar@vmJ bin]$ sudo rm journalctl 
[cesaaar@vmJ completions]$ history -c
```

---

## TP3B Part 3 - Create a template

### 1. Créer le template

De retour dans votre shell `az`, sur votre PC, on va créer le template.

**🌞 Let's go, balancez :**

```bash
az vm deallocate --resource-group TP2 --name vmJ
az vm generalize --resource-group TP2 --name  vmJ
az image create --resource-group TP2 --name alma_chad --source vmJ --hyper-v-generation V2
```

### 2. Tester le template

**🌞 Lancer une VM à partir de votre template**

Même commande `vm create` que d'habitude, mais choisissez votre image comme base avec un `--image alma_chad` :

```bash
az vm create -g TP2 -n vmJ2 --size Standard_B1s --image alma_chad --admin-username cesaaar --ssh-key-values "ssh-ed25519 ma clé ssh"
```

**🌞 Vérification !**

Connectez-vous à la VM :
```bash
cesaaar@fedora:~/Téléchargements/cours$ ssh cesaaar@9.205.154.210
...
Warning: Permanently added '9.205.154.210' (ED25519) to the list of known hosts.
```

Vérifiez que notre conf custom est bien appliquée et les services actifs :

```bash
[cesaaar@vmJ2 /]$ ping -h

[cesaaar@vmJ2 /]$ cloud-init status --wait
status: done

[cesaaar@vmJ2 /]$ systemctl status waagent
● waagent.service - Azure Linux Agent
     Active: active (running) since Mon 2026-03-23 14:21:25 UTC; 13min ago

[cesaaar@vmJ2 /]$ sudo firewall-cmd --list-all | grep ser
  services: ssh
```

---

## Part 4 - Hardening

**🌞 Firewall conf**

* Avoir `firewalld` comme firewall.
* Il est actif et lancé au démarrage de la machine.
* Seul le port `22/tcp` est ouvert.

**🌞 Prouvez que fail2ban fonctionne**

```bash
[cesaaar@vmJ2 ~]$ sudo fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed:	1
|  |- Total failed:	1
...
[cesaaar@vmJ2 ~]$ sudo fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed:	0
|  |- Total failed:	6
`- Actions
   |- Currently banned:	3
   |- Total banned:	3
   `- Banned IP list:	159.117.224.27 159.117.224.29 159.117.224.28
```

**🌞 Proposer une conf sysctl**

```bash
[cesaaar@vmJ2 ~]$ sudo sysctl -w net.ipv4.conf.all.rp_filter=1
# verifie si le chemin par lequel arrive les paquets est cohérent avec sa table de routage ce qui évite l'ARP Spoofing

[cesaaar@vmJ2 ~]$ sudo sysctl -w net.ipv4.tcp_syncookies=1
# Évite les attaques DDOS avec un systéme de hashage des informations du clients

[cesaaar@vmJ2 ~]$ sudo sysctl -w net.ipv4.conf.all.log_martians=1 
# Toute les connections bizarre sont repertoriées dans les logs
```

**🌞 Proposer une conf AIDE**

```conf
# --- DB PATH ---
database_in=file:/var/lib/aide/aide.db.gz
database_out=file:/var/lib/aide/aide.db.new.gz
gzip_dbout=yes

# --- RULE DEFINITION---
SECURE = p+i+n+u+g+s+m+c+sha256+sha512

# --- SSH FILES ---
/etc/ssh/sshd_config$   SECURE
/etc/ssh/ssh_config$    SECURE
/etc/ssh/.*\.pub$       SECURE
/etc/ssh/ssh_host.* SECURE

# --- Sysctl FILES ---
/etc/sysctl.conf$       SECURE
/etc/sysctl.d/.* SECURE
```

**🌞 Initialiser la base de données AIDE**

```bash
sudo aide --init
```

**🌞 Jouer avec les tests d'intégrité AIDE**

Premier test (tout est ok) :
```bash
[cesaaar@vmJ2 ~]$ sudo aide --check
AIDE found NO differences between database and filesystem. Looks okay!!
```

Après modification (kaboom) :
```bash
[cesaaar@vmJ2 ~]$ sudo aide --check
AIDE found differences between database and filesystem!!

Summary:
  Changed entries:		1

---------------------------------------------------
Changed entries:
---------------------------------------------------
f < ... mc..H    : /etc/ssh/sshd_config
```

**Configuration du Timer Systemd pour AIDE :**

```bash
cat /etc/systemd/system/aide-test.timer
[Unit]
Description=Lance un test d'intégrité AIDE chaque heure

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
[cesaaar@vmJ2 ~]$ systemctl list-timers aide-test.timer
NEXT                         LEFT LAST PASSED UNIT            ACTIVATES        
Tue 2026-03-24 12:00:00 UTC 53min -         - aide-test.timer aide-test.service
```

---

## TP3B Part 5 - Template then Deploy

### 1. Create the template

**🌞 Clean la VM**

Répéter les opérations de clean, reset de cloud-init, wagent et historique :

```bash
[cesaaar@vmJ2 log]$ sudo rm btmp cron dnf.librepo.log dnf.log dnf.rpm.log hawkey.log lastlog messages secure spooler waagent.log wtmp tuned/tuned.log 
[cesaaar@vmJ2 bin]$ sudo rm journalctl 
[cesaaar@vmJ2 completions]$ history -c
```

**🌞 Faire de la VM un template**

Nommez l'image `alma-hardened` :

```bash
az vm deallocate --resource-group TP2 --name vmJ2
az vm generalize --resource-group TP2 --name  vmJ2
az image create --resource-group TP2 --name alma_hardened --source vmJ2 --hyper-v-generation V2
```

### 2. Test

**🌞 Lancer une VM à partir de cette image**

```bash
az vm create -g TP2 -n vmJ3 --size Standard_B1s --image alma_chad --admin-username cesaaar --ssh-key-values "ssh-ed25519 macléssh"
```

**🌞 Vérif**

Connectez-vous et vérifiez la configuration :

```bash
cesaaar@fedora:~/Téléchargements/cours$ ssh cesaaar@9.205.154.47
[cesaaar@vmJ3 /]$ sudo firewall-cmd --list-all
```
