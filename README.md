# Firewall-fuer-DNS-layer-security
Application-Firewall im OSI-Layer 7 und stateful Firewall im OSI-Layer 3 und 4

## Übersicht:
  * Hardwarevoraussetzungen
  * Softwarevoraussetzungen
  * Installation aus den Paketquellen
  * Konfiguration/Kontrolle von ufw stateful Firewall
  * Konfiguration von suricata als Firewall
  * Konfiguration von suricata-update
  * fw_suricata.sh script anlegen und als unit in systemd einbinden
  * Kontrolle des Paketverlaufes von ufw und suricata
  * Test: syn-flood Attacke und Durchsatzmessung
  * Kommerzielle Anbieter von Netzwerk Schwachstellen-erkennung und - schutz


## Hardwarevoraussetzungen:
- x86_64 Minimum 4 cores and 8 GB RAM (je nach use case)
- arm_64 min. RaspberryPi 4b mit mindestens 2 GB RAM (je nach use case)
- Gbit/sec nic

## Softwarevoraussetzungen aus den Paketquellen:
- Debian - Bookworm
- ufw - Version: 0.36.2-1
- Suricata (IPS-mode) - Version: 1:6.0.10-1
- fw bash script - zum Laden  der NFQUEUE/suricata; eingebunden über die Units von systemd

## Installation aus den Paketquellen:

	$sudo apt install ufw suricata suricata-update iptables

## Konfiguration von ufw (uncomplicated firewall):

Verweis auf die Installationsanleitung von digitalocean -> https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu#step-5-allowing-other-connections
- Benötigte policy: deny incoming
- Benötigte ports: 22, 53, 80, 123, 443

## Kontrolle der stateful Firewall im OSI-Layer 3 und 4:

	$sudo ufw status verbose

Output
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                        		 Action      	From
--                         		 ------      	----
22/tcp (SSH)               		ALLOW IN    Anywhere                  
53 (DNS)                   		ALLOW IN    Anywhere                  
80,443/tcp (Nginx Full)    	  ALLOW IN    Anywhere                  
123/udp                    		ALLOW IN    Anywhere                  

22/tcp                     		ALLOW OUT   Anywhere                  
53 (DNS)                   		ALLOW OUT   Anywhere                  
80,443/tcp (Nginx Full)    	  ALLOW OUT   Anywhere                  
123/udp                    		ALLOW OUT   Anywhere


## Konfiguration von suricata als Firewall im OSI-Layer 7:

Verweis auf die Installationsanleitung von digitalocean -> https://www.digitalocean.com/community/tutorials/how-to-configure-suricata-as-an-intrusion-prevention-system-ips-on-debian-11
Die Anleitung funktioniert für Debian Bookworm gleichermaßen.

## Konfiguration von suricata-update:

Verweis auf die Installationsanleitung von suricata-update -> https://docs.suricata.io/en/latest/rule-management/suricata-update.html

Folgende Konfigurationsdateien sind entsprechend der Anleitung anzupassen und können verglichen werden, siehe update.yaml, drop.conf und die enable.conf.
Es wurden alle freien sources aktiviert und zusätzlich weitere in der update.yaml Datei. In der drop.conf sind die relevanten Regelgruppen angegeben worden, die von alert auf drop geändert werden sollen. Die enable.conf enthält rule groups, die per default Einstellung teilweise noch nicht aktiviert sind und somit aktiviert werden sollen.

## bash script fw_suricata.sh und die Unit suricata-firewall.service für systemd
#### Das bash script fw_suricata.sh beinhaltet das Queueing zum Userspace mittels NFQUEUE im OSI Layer 7
Das script installieren:
kopiere die Datei fw_suricata.sh ins Verzeichnis /etc/iptables
chmod 750 /etc/iptables/fw_suricata.sh # das script ausführbar machen
ls -la /etc/iptables # Kontrolle der Rechte des scripts 

## script start on boot via systemd:
  Erstellen der leeren Datei suricata-firewall.service und Inhalt des Templates suricata-firewall.service in die gleichnamige leere Datei über die Zwischenablage kopieren.

  nano /etc/systemd/system/suricata-firewall.service
  copy paste des Templateinhaltes + abspeichern
  systemctl start suricata-firewall # ausführen der Firewall
  systemctl enable suricata-firewall # ausführen der Firewall nach jedem Neustart

## Kontrolle:
  Visualisierung des Paketfverlaufes 

$sudo iptables -vnL

## Testen der Firewall mit einer syn-flood Attacke:
	$sudo apt install hping3
	$sudo hping3 -c 15000 -d 120 -S -w 64 -p 80 --flood --rand-source 192.168.1.4      # IP entsprechend anpassen

Output
HPING 192.168.1.4 (enp2s0 192.168.1.4): S set, 40 headers + 120 data bytes
hping in flood mode, no replies will be shown
^C
--- 192.168.1.4 hping statistic ---
566855 packets transmitted, 0 packets received, 100% packet loss
round-trip min/avg/max = 0.0/0.0/0.0 ms


Für die Dauer der Attacke sind die Dienste hinter der Firewall nicht erreichbar, da die Performance der
NIC Hardware zu schwach ist. Aber nach der Attacke sollte es uneingeschränkt ohne Absturz oder Verzögerungen im Normalbetrieb weitergehen.

## Durchsatzmessung auf dem RaspberryPi als client:
	$sudo apt install iperf   # Sowohl auf dem Klienten und auf dem Server installieren (
	$iperf -s # zum Starten auf dem Server ausführen
	$sudo iperf -c 192.168.1.15    # startet den Klienten / IP-Adresse entsprechend anpassen

=> 858 Mbits/sec von 1.000 Mbit/s 	das ist OK

Damit ist die Next Generation Firewall installiert und die Funktionsweise getestet.

## Kommerzielle Anbieter Netzwerk Schwachstellen-erkennung und -schutz

- openVAS Vulnerability scanner, https://www.greenbone.net
- NodeZero Platform von Horizon3 AI, automatisches Pentesting, http://horizon3.ai/
- SentinelOne Singularity™️ XDR Platform und KI gestützte anomaly detection,  https://de.sentinelone.com
