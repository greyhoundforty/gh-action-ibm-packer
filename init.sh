#!/usr/bin/env bash 

set -e
set -x

LOGFILE="/tmp/packer-installer.log"

echo -e "Hello from Packer template: `hostname -s`" | tee -a "$LOGFILE"


main() {
    export NEEDRESTART_MODE=a
    export DEBIAN_FRONTEND=noninteractive
    export DEBIAN_PRIORITY=critical
    
    install_system_packages() {
        echo -e "[:: Updating system packages ::]" 
        apt-get -qy clean
        apt-get -qy update
        apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade

        echo -e "[:: Installing base tools ::]" 
        apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install linux-headers-$(uname -r) curl wget apt-transport-https ca-certificates software-properties-common
    } >> "$LOGFILE" 2>&1

    install_hashistack_tools() {
        echo -e "[:: Add HashiCorp GPG Key and Repo ::]" 
        export NEEDRESTART_MODE=a
        export DEBIAN_FRONTEND=noninteractive
        export DEBIAN_PRIORITY=critical

        ## Add Hashicorp GPG key and repo 
        wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
        
        echo -e "[:: Installing Consul, Nomad, and Vault ::]" 
        ## Update the package list and install Consul, Nomad, and Vault.
        apt-get -qy update
        apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install consul nomad vault 
    } >> "$LOGFILE" 2>&1

    install_docker() {
        echo -e "[:: Add Docker GPG Key and Repo ::]" 
        ## Add Docker GPG key and repo 
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

        echo -e "[:: Installing Docker ::]"
        ## Update the package list and install Docker.
        apt-get -qy update
        apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install docker-ce
   
    } >> "$LOGFILE" 2>&1

    install_system_packages 
    install_hashistack_tools
    install_docker

} 

main

