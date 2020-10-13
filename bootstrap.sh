#!/bin/bash

set -ex

export DEBIAN_FRONTEND=noninteractive

echo "waiting 180 seconds for cloud-init to update /etc/apt/sources.list"
timeout 180 /bin/bash -c \
  'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 1; done'

apt-get update && apt-get -y upgrade
apt-get -y install \
    curl \
    wget \
    apt-transport-https \
    ca-certificates \
    curl \
    sudo \
    gnupg-agent \
    software-properties-common \
    openjdk-8-jdk \
    vim \
    bash-completion \
    jq

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

sudo usermod -aG docker root

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

mkdir -p /opt/docker-compose
cp -a /tmp/resources/compose/* /opt/docker-compose

# cp -a /tmp/resources/*.sh /usr/bin
cp -a /tmp/resources/*.service /lib/systemd/system/
systemctl daemon-reload

systemctl enable docker code-server
systemctl start docker code-server

cp -a /tmp/resources/bin/* /usr/local/bin

for i in $(find /opt/docker-compose -mindepth 1 -maxdepth 1 -type d); do
  pushd "$i"
  docker-compose pull
  popd

  svc=$(basename "$i")
  systemctl enable docker-compose@$svc
done

curl -fsSL https://code-server.dev/install.sh | sh -s -- --prefix /usr/bin

code-server --install-extension puppet.puppet-vscode

mkdir -p /root/.config/code-server

cat >/root/.config/code-server/config.yaml <<EOF
auth: none
EOF

cat >/root/.local/share/code-server/User/settings.json <<EOF
{
    "workbench.colorTheme": "Visual Studio Dark",
    "editor.formatOnSave": true,
    "editor.fontSize": 14,
    "editor.tabSize": 2,
    "files.autoSave": "afterDelay",
    "window.menuBarVisibility": "hidden",
    "workbench.startupEditor": "none",
    "editor.minimap.enabled": false,
    "terminal.integrated.shell.linux": "/bin/bash"
}
EOF