#!/bin/bash

set -ex

export DEBIAN_FRONTEND=noninteractive

echo "waiting 180 seconds for cloud-init to update /etc/apt/sources.list"
timeout 180 /bin/bash -c \
  'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 1; done'

wget https://apt.puppetlabs.com/puppet-release-bionic.deb
dpkg -i puppet-release-bionic.deb
rm -rf puppet-release-bionic.deb

wget https://apt.puppet.com/puppet-tools-release-bionic.deb
dpkg -i puppet-tools-release-bionic.deb
rm -rf puppet-tools-release-bionic.deb

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
    jq \
    puppetserver \
    puppet-agent \
    puppet-bolt \
    ntp

service ntp restart

cp -a /tmp/resources/*.service /lib/systemd/system/
systemctl daemon-reload

systemctl enable code-server
systemctl start code-server

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