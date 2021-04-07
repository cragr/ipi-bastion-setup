#!/bin/bash
# Create Disconnected Registry
# Source: https://access.redhat.com/articles/5489341

source 0_vars

# Show sudo permissions
echo "Showing sudo permissions"
sudo -l

# Create the required folders for the Registry
sudo mkdir -p /opt/registry/{auth,certs,data,conf}

# Create TLS certs for our registry 
sudo openssl req -newkey rsa:4096 -nodes -sha256 -subj "${REG_CERT_SUBJ}" -keyout /opt/registry/certs/registry.key -x509 -days 3650 -out /opt/registry/certs/registry.crt

# Create registry credentials
sudo htpasswd -bBc /opt/registry/auth/htpasswd admin redhat

# Configure our registry to accept schema1 images.
cat <<EOF | sudo tee /opt/registry/conf/config.yml
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
compatibility:
  schema1:
    enabled: true
EOF

# Configure SystemD unit files for starting/stopping our registry
cat <<EOF | sudo tee /etc/systemd/system/podman-registry.service
[Unit]
Description=Podman container - Docker Registry
After=network.target

[Service]
Type=simple
WorkingDirectory=/root
TimeoutStartSec=300
ExecStartPre=-/usr/bin/podman rm -f registry
ExecStart=/usr/bin/podman run --name registry --net host -e REGISTRY_AUTH=htpasswd -e REGISTRY_AUTH_HTPASSWD_REALM=Registry -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd -e REGISTRY_HTTP_SECRET=YourOwnLongRandomSecret -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/registry.crt -e REGISTRY_HTTP_TLS_KEY=/certs/registry.key -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/registry -v /opt/registry/auth:/auth:z -v /opt/registry/certs:/certs:z -v /opt/registry/data:/registry:z -v /opt/registry/conf/config.yml:/etc/docker/registry/config.yml:z registry:2.7
ExecStop=-/usr/bin/podman rm -f image-registry
Restart=always
RestartSec=30s
StartLimitInterval=60s
StartLimitBurst=99

[Install]
WantedBy=multi-user.target
EOF

# Install the unit file in the system and start the registry
sudo systemctl daemon-reload
sudo systemctl enable podman-registry --now

# Add the registry certificate to the O.S trust store 
sudo cp /opt/registry/certs/registry.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust

# Wait 5 seconds
echo "Waiting 5 seconds for container to start"
sleep 5

# Test the registry connectivity
curl -u admin:redhat -k https://${HOSTNAME}:5000/v2/_catalog
