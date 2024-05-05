#!/bin/bash

### Die NFQUEUE-bypass option stellt den Zugang zu ssh sicher. Quelle: digitalocean.com Suricata IPS-mode
## https://www.digitalocean.com/community/tutorials/how-to-configure-suricata-as-an-intrusion-prevention>
##
## script installieren:
## copy fw_suricata.sh to /etc/iptables
## chmod 750 /etc/iptables/fw_suricata.sh
##
## script start on boot via systemd:
## nano /etc/systemd/system/suricata-firewall.service erstellen und Template einfügen
## systemctl start suricata-firewall
## systemctl enable suricata-firewall 

##
##
## Start Suricata NFQUEUE rules

rule_exists() {
    local chain=$1
    local rule=$2
    iptables -C "$chain" $rule 2>/dev/null
    return $?
}

# Check and add rules to the INPUT chain
if ! rule_exists INPUT "-p tcp --dport 22 -j NFQUEUE --queue-bypass"; then
    iptables -I INPUT 1 -p tcp --dport 22 -j NFQUEUE --queue-bypass
fi

if ! rule_exists INPUT "-j NFQUEUE"; then
    iptables -A INPUT -j NFQUEUE
fi

# Check and add rule to the FORWARD chain
if ! rule_exists FORWARD "-j NFQUEUE"; then
    iptables -A FORWARD  -j NFQUEUE
fi

# Check and add rules to the OUTPUT chain
if ! rule_exists OUTPUT "-p tcp --sport 22 -j NFQUEUE --queue-bypass"; then
    iptables -A OUTPUT -p tcp --sport 22 -j NFQUEUE --queue-bypass
fi

if ! rule_exists OUTPUT "-j NFQUEUE"; then
    iptables -I OUTPUT 2 -j NFQUEUE
fi
## End Suricata NFQUEUE rules