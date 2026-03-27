# Part I : Docker basics

## 1. Install

**🌞 Installer Docker votre machine Azure**

en suivant la doc officielle:

```bash
sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

démarrer le service docker avec une commande systemctl:

```bash
sudo systemctl start docker
```

ajouter votre utilisateur au groupe docker

cela permet d'utiliser Docker sans avoir besoin de l'identité de root

avec la commande : `sudo usermod -aG docker $(whoami)`

```bash
sudo usermod -aG docker $(whoami)
```

déconnectez-vous puis relancez une session pour que le changement prenne effet

## 3. Lancement de conteneurs

**🌞 Utiliser la commande docker run**

lancer un conteneur nginx

conf par défaut étou étou, simple pour le moment
par défaut il écoute sur le port 80 et propose une page d'accueil

le conteneur doit être lancé avec un partage de port

le port 9999 de la machine hôte doit rediriger vers le port 80 du conteneur

```bash
cesaaar@fedora:~/Téléchargements$ docker run --name web -d -p 9999:80 nginx
b50b7004f5fdc9ee62d995b82075e007f69d26071d9a18203d533ae19f5fd90b
```

**🌞 Rendre le service dispo sur internet**

il faut peut-être ouvrir un port firewall dans votre VM (suivant votre OS, ptet y'en a un, ptet pas)
il faut ouvrir un port dans l'interface web de Azure (appelez moi si vous trouvez pas)
vous devez pouvoir le visiter avec votre navigateur (un curl m'ira bien pour le compte-rendu)

```html
cesaaar@fedora:~/Téléchargements$ curl http://10.100.0.56:9999/
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, nginx is successfully installed and working.
Further configuration is required for the web server, reverse proxy, 
API gateway, load balancer, content cache, or other features.</p>

<p>For online documentation and support please refer to
<a href="https://nginx.org/">nginx.org</a>.<br/>
To engage with the community please visit
<a href="https://community.nginx.org/">community.nginx.org</a>.<br/>
For enterprise grade support, professional services, additional 
security features and capabilities please refer to
<a href="https://f5.com/nginx">f5.com/nginx</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

**🌞 Custom un peu le lancement du conteneur**

* l'app NGINX doit avoir un fichier de conf personnalisé pour écouter sur le port 7777 (pas le port 80 par défaut)
* l'app NGINX doit servir un fichier index.html personnalisé (pas le site par défaut)
* l'application doit être joignable grâce à un partage de ports (vers le port 7777)
* vous limiterez l'utilisation de la RAM du conteneur à 512M
* le conteneur devra avoir un nom : meow

```bash
cesaaar@fedora:~/Téléchargements$ docker run --name meow -d -m 512m -v /home/cesaaar/Téléchargements/cours/tp_docker_cloud/index.html:/usr/share/nginx/html/index.html -v /home/cesaaar/Téléchargements/cours/tp_docker_cloud/ng.conf:/etc/nginx/conf.d/ng.conf -p 7777:7777 nginx
```

---

# Part II : Images

**🌞 Construire votre propre image**

image de base (celle que vous voulez : debian, alpine, ubuntu, etc.)

* une image du Docker Hub
* qui ne porte aucune application par défaut

vous ajouterez

* mise à jour du système
* installation de Apache (pour les systèmes debian, le serveur Web apache s'appelle apache2 et non pas httpd comme sur Rocky)
* page d'accueil Apache HTML personnalisée

**🌞 Dans les deux cas, j'attends juste votre Dockerfile dans le compte-rendu :**

```dockerfile
FROM debian

RUN apt update -y

RUN apt install -y apache2

RUN mkdir -p /etc/apache2/logs

COPY index.html /var/www/html/index.html

COPY apache2.conf /etc/apache2/apache2.conf

CMD ["apache2ctl", "-D", "FOREGROUND"]
```

---

# Part III : docker-compose

## 2. WikiJS

**🌞 Installez un WikiJS en utilisant Docker**

* WikiJS a besoin d'une base de données pour fonctionner
* il faudra donc deux conteneurs : un pour WikiJS et un pour la base de données
* référez-vous à la doc officielle de WikiJS, c'est tout guidé

```yaml
version: "3.8"

services:

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: wiki
      POSTGRES_PASSWORD: secret
      POSTGRES_USER: wikijs
    logging:
      driver: none
    restart: unless-stopped
    volumes:
      - db-data:/var/lib/postgresql/data

  wiki:
    image: ghcr.io/requarks/wiki:2
    depends_on:
      - db
    environment:
      DB_TYPE: postgres
      DB_HOST: db
      DB_PORT: 5432
      DB_USER: wikijs
      DB_PASS: secret
      DB_NAME: wiki
    restart: unless-stopped
    ports:
      - "80:3000"

volumes:
  db-data:
```

## 3. Make your own meow

**🌞 Vous devez :**

construire une image qui

* contient python3
* contient l'application et ses dépendances
* lance l'application au démarrage du conteneur :

```dockerfile
FROM python:3.11

RUN apt update -y

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY app.py .

COPY templates/ ./templates/

CMD ["python3", "app.py"]
```

écrire un docker-compose.yml qui définit le lancement de deux conteneurs

* l'app python
* le Redis dont il a besoin :

```yaml
version: "3.8"

services:
  python:
    build: .
    image: pytone
    ports:
      - "8888:8888"

  db:
    image: redis:alpine
```

---

# Part IV : Docker security

**🌞 Prouvez que vous pouvez devenir root**

en étant membre du groupe docker

* sans taper aucune commande sudo ou su ou ce genre de choses
* normalement, une seule commande docker run suffit
* pour prouver que vous êtes root, plein de moyens possibles

par exemple un `cat /etc/shadow` qui contient les hash des mots de passe de la machine hôte
normalement, seul root peut le faire

```text
cesaaar@fedora:~/Téléchargements/cours/tp_docker_cloud$ docker run -d nginx
f2950ba814e39297becb31573c1639c15d33e33993165f23c613c96674ad3829
cesaaar@fedora:~/Téléchargements/cours/tp_docker_cloud$ cat /etc/passwd
root:x:0:0:Super User:/root:/bin/bash
bin:x:1:1:bin:/bin:/usr/sbin/nologin
daemon:x:2:2:daemon:/sbin:/usr/sbin/nologin
adm:x:3:4:adm:/var/adm:/usr/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/usr/sbin/nologin
sync:x:5:0:sync:/sbin:/bin/sync
shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
halt:x:7:0:halt:/sbin:/sbin/halt
mail:x:8:12:mail:/var/spool/mail:/usr/sbin/nologin
operator:x:11:0:operator:/root:/usr/sbin/nologin
games:x:12:100:games:/usr/games:/usr/sbin/nologin
```

## 2. Scan de vuln

Il existe des outils dédiés au scan de vulnérabilités dans des images Docker.
C'est le cas de Trivy par exemple.

**🌞 Utilisez Trivy**

effectuez un scan de vulnérabilités sur des images précédemment mises en oeuvre :

* celle de WikiJS que vous avez build
* celle de sa base de données
* l'image de Apache que vous avez build
* l'image de NGINX officielle utilisée dans la première partie

```text
cesaaar@fedora:~/Téléchargements/cours/tp_docker_cloud$ trivy image apachee
2026-03-19T15:10:49+01:00	INFO	[vulndb] Need to update DB
2026-03-19T15:10:49+01:00	INFO	[vulndb] Downloading vulnerability DB...
2026-03-19T15:10:49+01:00	INFO	[vulndb] Downloading artifact...	repo="mirror.gcr.io/aquasec/trivy-db:2"
88.14 MiB / 88.14 MiB [------------------------------------------------------------------------------------------------------------------------------------------------] 100.00% 14.65 MiB p/s 6.2s
2026-03-19T15:10:56+01:00	INFO	[vulndb] Artifact successfully downloaded	repo="mirror.gcr.io/aquasec/trivy-db:2"
2026-03-19T15:10:56+01:00	INFO	[vuln] Vulnerability scanning is enabled
2026-03-19T15:10:56+01:00	INFO	[secret] Secret scanning is enabled
2026-03-19T15:10:56+01:00	INFO	[secret] If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2026-03-19T15:10:56+01:00	INFO	[secret] Please see also https://trivy.dev/dev/docs/scanner/secret#recommendation for faster secret detection
2026-03-19T15:11:01+01:00	INFO	Detected OS	family="debian" version="13.4"
2026-03-19T15:11:01+01:00	INFO	[debian] Detecting vulnerabilities...	os_version="13" pkg_num=133
2026-03-19T15:11:01+01:00	INFO	Number of language-specific files	num=0
2026-03-19T15:11:01+01:00	WARN	Using severities from other vendors for some vulnerabilities. Read https://trivy.dev/dev/docs/scanner/vulnerability#severity-selection for details.

Report Summary

┌────────────────────────────────────────┬────────┬─────────────────┬─────────┐
│                 Target                 │  Type  │ Vulnerabilities │ Secrets │
├────────────────────────────────────────┼────────┼─────────────────┼─────────┤
│ apachee (debian 13.4)                  │ debian │       163       │    -    │
├────────────────────────────────────────┼────────┼─────────────────┼─────────┤
│ /etc/ssl/private/ssl-cert-snakeoil.key │  text  │        -        │    1    │
└────────────────────────────────────────┴────────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


apachee (debian 13.4)

Total: 163 (UNKNOWN: 1, LOW: 146, MEDIUM: 15, HIGH: 1, CRITICAL: 0)



cesaaar@fedora:~/Téléchargements/cours/tp_docker_cloud$ trivy image ghcr.io/requarks/wiki:2

Node.js (node-pkg)

Total: 131 (UNKNOWN: 0, LOW: 14, MEDIUM: 41, HIGH: 68, CRITICAL: 8)


ghcr.io/requarks/wiki:2 (alpine 3.23.3)

Total: 7 (UNKNOWN: 0, LOW: 0, MEDIUM: 4, HIGH: 2, CRITICAL: 1)

cesaaar@fedora:~/Téléchargements/cours/tp_docker_cloud$ trivy image --format table --quiet postgres:15-alpine


postgres:15-alpine (alpine 3.23.3)

Total: 2 (UNKNOWN: 0, LOW: 0, MEDIUM: 1, HIGH: 1, CRITICAL: 0)


usr/local/bin/gosu (gobinary)

Total: 19 (UNKNOWN: 0, LOW: 1, MEDIUM: 12, HIGH: 5, CRITICAL: 1)


cesaaar@fedora:~/Téléchargements/cours/tp_docker_cloud$ trivy image --format table --quiet my_own_nginx


my_own_nginx (debian 13.4)

Total: 163 (UNKNOWN: 1, LOW: 146, MEDIUM: 15, HIGH: 1, CRITICAL: 0)

/etc/ssl/private/ssl-cert-snakeoil.key (secrets)

Total: 1 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 1, CRITICAL: 0)
```
