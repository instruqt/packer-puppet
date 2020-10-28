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
    "workbench.colorTheme": "Default Dark+",
    "workbench.statusBar.visible": false,
    "workbench.tips.enabled": false,
    "workbench.startupEditor": "newUntitledFile",
    "update.showReleaseNotes": false,
    "telemetry.enableTelemetry": false,
    "window.menuBarVisibility": "hidden",
    "workbench.activityBar.visible": false,
    "breadcrumbs.enabled": false,
    "breadcrumbs.filePath": "off",
    "workbench.editor.enablePreview": false,
    "workbench.editor.enablePreviewFromQuickOpen": false,
    "workbench.editor.highlightModifiedTabs": true,
    "workbench.editor.showTabs": false,
    "files.enableTrash": false,
    "files.autoSave": "afterDelay",
    "workbench.enableExperiments": false,
    "editor.formatOnSave": true,
    "editor.codeLens": false,
    "editor.colorDecorators": false,
    "editor.dragAndDrop": false,
    "editor.smoothScrolling": true,
    "editor.minimap.enabled": false,
    "editor.fontSize": 14,
    "terminal.integrated.shell.linux": "/bin/bash"
    "workbench.colorCustomizations": {
        "sideBar.background": "#252F42",
        "sideBar.foreground": "#fff",
        "editor.background": "#1C2639",
        "list.activeSelectionBackground": "#344156",
        "list.focusBackground": "#344156",
        "list.hoverBackground": "#13171e",
        "list.inactiveSelectionBackground": "#344156"
    }
}
EOF