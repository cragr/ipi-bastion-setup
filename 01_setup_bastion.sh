#!/bin/bash

source 0_vars

# Install required software
sudo dnf -y install podman httpd httpd-tools openssl jq

echo "Downloading release $BUILDNUMBER..."

# Download RHCOS ova image
curl -s -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${RHCOS}/latest/rhcos-vmware.x86_64.ova

# Move ova image to httpd path
if [ ! -d /var/www/html ]; then
  echo "WARNING:  /var/www/html does not exist!  Please make sure to install httpd service on this system.  The rhcos installer files will need to be copied to /var/www/html directory manually once HTTPD is installed." >&2
  exit 1
else
  sudo rm -f /var/www/html/rhcos-vmware.x86_64.ova
  sudo mv rhcos-vmware.x86_64.ova /var/www/html
  sudo chmod 644 /var/www/html/rhcos-vmware.x86_64.ova
fi

# Download client and installer binaries
curl -s -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${RELEASE}/${CLIENT}
tar xzvf ${CLIENT}
curl -s -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${RELEASE}/${INSTALLER}
tar xzvf ${INSTALLER}
sudo rm -f /usr/local/bin/oc /usr/local/bin/kubectl /usr/local/bin/openshift-install
sudo cp oc kubectl openshift-install /usr/local/bin
sudo chmod +x /usr/local/bin/oc /usr/local/bin/kubectl /usr/local/bin/openshift-install
sudo rm -f oc kubectl openshift-install README.md
sudo rm -f ${CLIENT} ${INSTALLER}

# Setup podman and httpd for local registry and webserver 
sudo firewall-cmd --add-port=5000/tcp --zone=internal --permanent
sudo firewall-cmd --add-port=5000/tcp --zone=public   --permanent
sudo firewall-cmd --add-service=http  --permanent
sudo firewall-cmd --reload