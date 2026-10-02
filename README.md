# mcserver
Mit diesem Repo wird ein Minecraftserver auf einem Raspberry Pi aufgesetzt. <br>

Es wurden ein **Pi 5, 32GB SD-Karte** und **32GB USB-Stick** für Backups verwendet.
<br>
<br>
<br>

## Raspberry Pi aufsetzen
Anleitung von raspberry.tips:
> https://raspberry.tips/raspberrypi-infos/installation-und-einrichtung-des-raspberry-pi <br>

Raspberry Pi Imager:
>https://www.raspberrypi.com/software/ <br>

<br>

### IPv4
IP: 192.168.x.x  
Subnetz: 255.255.x.x  
Gateway: 192.168.x.x  
DNS: 192.168.x.x  <br>

<br>

### Remoteverbindung
Über **PuTTY** mittels **SSH**  
>https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html  <br>

SSH aktivieren, PuTTY installieren 

mittels SSH auf Pi-IP aufschalten und als admin anmelden <br>
<br>

*ODER*
<br>
<br>

**TigerVNC** für **GUI**<br>
>https://sourceforge.net/projects/tigervnc/ <br>

im Terminal: <code>sudo raspi-config → 3 Interface Options → 3 VNC → aktivieren</code> <br>

<br>
<br>
<br>

## Docker
>https://marc.tv/minecraft-java-raspberry-pi-docker/ 
<br>

### Docker installieren
    cd
    mkdir mcserver
    curl -fsSL https://get.docker.com -o get-docker.sh
    chmod +x get-docker.sh 
    ./get-docker.sh 
    sudo apt-get install -y uidmap
    dockerd-rootless-setuptool.sh install
    sudo usermod -aG docker $USER
    sudo systemctl enable docker
    newgrp docker

cd - home-verzeichnis

<code>mkdir mcserver</code> - ordner mcserver erstellen

<code>curl -fsSL https://get.docker.com -o get-docker.sh</code> - docker installieren

<code>chmod +x get-docker.sh</code> - sh mit dockerinstallationsskript ausführbar machen

<code>./get-docker.sh</code> - sh ausführen / docker installieren

<code>sudo apt-get install -y uidmap</code> - uidmap installieren, damit docker nicht im adminmodus ausgeführt wird

<code>dockerd-rootless-setuptool.sh install</code> - docker als nicht-admin-modus installieren

<code>sudo systemctl enable docker</code> - docker nach systemneustart automatisch starten

<code>sudo usermod -aG docker $USER</code> - docker gruppe anlegen und $USER hinzufügen, damit docker ohne rootrechte ausgeführt wird

<code>newgrp docker</code> - in docker gruppe wechseln  
<br>
<br>

### docker-compose.yml
    name: mcserver
    services:
        mcserver:
            container_name: mcserver
            environment:
                MEMORYSIZE: 3G
                PAPERMC_FLAGS: ""
            image: marctv/minecraft-papermc-server:latest
            networks:
                default: null
            ports:
                - "25565:25565"
            restart: unless-stopped
            volumes:
                - type: bind
                  source: /home/admin/mcserver/weltdaten
                  target: /data
                  bind: {}
    networks:
        default:
            name: mcserver_default
<br>
<br>

### Logs anschauen
    sudo docker logs mcserver --follow

<br>
<br>
<br>

## Verbindung zum Minecraft Server
1. Minecraft Version 26.2 (je nach latest release von papermc) starten

2. bei Multiplayer die IP des Pis als Serveradresse hinterlegen

<br>
<br>
<br>

## Sicherung
>https://raspberry.tips/raspberrypi-tutorials/raspberry-pi-datensicherung-erstellen <br>

<br>

### shrink-backup
>https://github.com/UnconnectedBedna/shrink-backup <br>

erstellt bootbare .img Dateien
<br>

*USB-Stick mit exFAT(ext4)-dateifomat benötigt, um große Dateien speichern zu können*<br>
<br>

#### USB-Stick formatieren
>https://www.diskpart.de/usb-stick-mit-diskpart-formatieren/<br>

>https://learn.microsoft.com/de-de/windows-server/administration/windows-commands/diskpart<br>

    diskpart
    list disk
    select disk 1
    clean
    create partition primary
    format fs=exFAT quick
<br>

Stick auf dem Pi prüfen:<br>

    lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS
<br>
<br>

#### .img erstellen

    curl https://raw.githubusercontent.com/UnconnectedBedna/shrink-backup/install/installer.sh | sudo bash
<br>


    sudo /home/admin/shrink-backup/shrink-backup -al /mnt/backup/FILENAME.img
<br>

<code>/home/admin/shrink-backup/shrink-backup</code> - da liegt die software shrink-backup

<code>-al</code> - kopiert alles (a) und generiert logs (l)

<code>/mnt/backup/FILENAME.img</code> - Ziel der .img <br>

<br>

### rsync
für manuelle Backups, ist bereits vorinstalliert - ist irrelevant für automatisierte Backups<br>

ggf. mit <code>mkdir</code> Ordner für Backup erstellen<br>

    sudo rsync -av /home/ /mnt/backup/weltdaten
<br>

<code>rsync</code>

<code>-a</code> - Archivmodus: kopiert Unterordner rekursiv und erhält möglichst Besitzer, Rechte, Zeitstempel und symbolische Links

<code>-v</code> - verbose: zeigt an, welche Dateien kopiert werden

<code>-z</code> - Komprimierung, nur bei Übertragung via netzwerk sinnvoll

<code>-n</code> - dry run: Probelauf

<code>--delete</code> - löscht Dateien, die im Originalen Image nicht vorhanden sind

<code>/home/</code> - zu sicherndes Verzeichnis

<code>/mnt/backup/weltdaten</code> - Zielverzeichnis

<br>

Daten der Welt liegen unter <code>/home/admin/mcserver</code> (vorher in docker-compose.yml gesetzt)

<br>
<br>

### mount USB-drive
>https://raspberry.tips/raspberrypi-tutorials/raspberry-pi-usb-festplatte-einrichten<br>

    # in Ausgangsverzeichnis gehen
    cd

    # Ordner für Backups erstellen
    sudo mkdir /mnt/backup

    # UUID des sticks ermitteln
    sudo blkid

    # Stick mittels ID mit Ordner koppeln; nofail, damit nichts abschmiert, wenn der mal nicht gekoppelt ist; user 1000 1000 damit ich dinge copy pasten kann
    sudo nano /etc/fstab       # UUID=EURE-UUID  /mnt/backup  exfat  defaults,nofail,uid=1000,gid=1000  0  0

    # stick mounten
    sudo mount -va
<br>

Der Stick wird automatisch erkannt, wenn er beim Bootvorgang schon steckt. Wird er nachträglich eingesteckt, muss er manuell mittels <code>sudo mount -va</code> gemountet werden.

Backups müssen in <code>/mnt/backup</code> geschoben werden und sind dann automatisch auf dem USB-Stick.<br>

<br>

### cronjob
>https://raspberry.tips/raspberrypi-einsteiger/cronjob-auf-dem-raspberry-pi-einrichten<br>

>https://www.tecmint.com/linux-file-backup-script/<br>

<code>backup-FOLDER.sh</code> unter <code>home/admin/etc/cron.daily</code>  (was in diesem Ordner liegt, wird täglich ausgeführt):<br>

    #!/bin/bash

    # Define source and destination directories
    SOURCE_DIR="/home/admin/mcserver/weltdaten"     # Source directory to back up
    BACKUP_DIR="/mnt/backup/weltdaten"       # Destination directory for backups

    # Create a timestamp for the backup folder
    TIMESTAMP=$(date +'%Y%m%d%H%M%S')

    # Create a new backup folder with the timestamp
    BACKUP_FOLDER="$BACKUP_DIR/backup_$TIMESTAMP"
    mkdir -p "$BACKUP_FOLDER"

    # Copy files to the backup folder
    cp -r "$SOURCE_DIR"/* "$BACKUP_FOLDER"

    # Log the completion of the backup
    echo "Backup completed at $TIMESTAMP" >> "$BACKUP_DIR/backup_log.txt"

    # Optional: Remove backups older than 30 days
    find "$BACKUP_DIR" -type d -name "backup_*" -mtime +30 -exec rm -rf {} \;
<br>

<code>SOURCE_DIR</code> - The directory containing the files you want to back up (e.g., /home/user/Documents).

<code>BACKUP_DIR</code> - The directory where backups will be stored (e.g., /home/user/backups).

<code>TIMESTAMP</code> - A variable that stores the current date and time to uniquely identify each backup folder.

<code>mkdir -p</code> - Creates the backup folder with the timestamp.

<code>cp -r</code> - Copies all files and subdirectories from the source directory to the backup folder.

<code>echo</code> - logs the backup completion and adds a timestamp to the log file.

<code>find</code> - removes backups older than 30 days, keeping your backup directory from filling up with old files.

<br>

Zeit des Backups unter <code>sudo nano /etc/crontab
</code> anpassen <br>

bspw:<br>

    20 11 * * * root test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )
erstellt um 11:20 ein Backup

<br>
<br>
<br>

## Monitoring
> https://raspberry.tips/raspberrypi-tutorials/raspberry-pi-monitoring-prometheus-grafana<br>

    git clone https://github.com/raspberry-tips/raspberry-pi-monitoring
<br>

    sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.bak
<br>

    sudo nano /boot/firmware/cmdline.txt

<code>cgroup_enable=memory cgroup_memory=1</code> ans Zeilenende mit Leerzeichen getrennt anhängen, damit RAM-Werte erfasst werden können

<br>
<br>

    sudo reboot
    # nach dem Neustart:
    cat /sys/fs/cgroup/cgroup.controllers
    # Ausgabe sollte memory beinhalten

<br>
<br>

in <code>compose.yaml</code> <code>GF_SECURITY_ADMIN_PASSWORD: bitte-aendern</code> selbst gewähltes Passwort setzen (wird für Erstanmeldung bei Grafana gebraucht)  
<br>
in <code>grafana/provisioning/alerting/contactpoints.yml</code> <code> ntfy "topic":"your-topic-name-here"</code> entsprechend anpassen (wird für Versand von Alerts aus Grafana an Mobilgeräte benötigt)
<br>

Docker Container staten
    cd raspberry-pi-monitoring
    docker compose up -d

*optional:* **ntfy** für Smartphone downloaden, topic abonnieren, und Push-Benachrichtugungen bei gesetzten Alarmen innerhalb Grafanas erhalten

![ntfy notification](/screenshots/ntfy-mobile.jpg)<br>

![ntfy notification](/screenshots/grafana-dashboard.png)<br>

<br>
<br>

## Wiederanlaufplan - RTO 1-2h
1. SD-Karte des Backup Pis mit reinem Image bespielen - Netzwerkkonfig, User anlegen, SSH aktivieren

2. SD-Karte in neuen Pi stecken, USB-Stick anstecken, Pi starten

3. IP auslesen / Adresse konfigurieren

4. git clone https://github.com/hannabanana-debug/mcserver.git

5. docker installieren
    - cd
    - curl -fsSL https://get.docker.com -o [get-docker.sh](http://get-docker.sh)
    - chmod +x [get-docker.sh](http://get-docker.sh)
    - ./get-docker.sh
    - sudo apt-get install -y uidmap
    - dockerd-rootless-setuptool.sh install
    - sudo usermod -aG docker \$USER
    - sudo systemctl enable docker
    - newgrp docker

6. mount USB-Stick
    - sudo mkdir /mnt/backup
    - sudo blkid
    - sudo nano /etc/fstab # UUID=EURE-UUID /mnt/backup  exfat  defaults,nofail,uid=1000,gid=1000  0  0
    - sudo mount -va

7. Weltdaten wiederherstellen
    - cp -r /mnt/backup/weltdaten/\* /home/admin/mcserver/weltdaten

8. Rechte auf diesen Ordner ändern, damit Docker kopierte Ordner/Dateien verwenden kann
    - sudo chown -R 1000:1000 /home/admin/mcserver/weltdaten
    - sudo chmod -R u+rwX /home/admin/mcserver/weltdaten

9. Docker Container starten
    - cd /home/admin/mcserver
    - docker compose up -d
    - docker compose logs -f
10. Erreichbarkeit des Servers/Weltstand prüfen

11. Monitoring wiederherstellen und testen (raspi-IP:3000)
    - cp -r /mnt/backup/monitoring/\* /home/admin/monitoring

12. Backups einrichten
    - mv /home/admin/mcserver/backup-weltdaten.sh /etc/cron-daily
    - mv /home/admin/mcserver/backup-monitoring.sh /etc/cron-daily
    - sudo nano /etc/crontab
