#!/usr/bin/env bash

# PiMediaSync Installer
#
# This script installs the PiMediaSync application and enables the systemd
# service so that it runs at boot.
#
# This script is designed to be run by other scripts to setup configuration and
# media files for specific installations.
# 
# On its own, this script will enable a simple default configuration
# (example_config.py).

set -e

if [ $(whoami) != 'root' ]; then
    echo 'Must be run as root.'
    exit 1
fi

HOMEDIR=${HOMEDIR:-/opt}
WORKDIR=${HOMEDIR}/pimediasync

# setup the of device
PIHOSTNAME=${PIHOSTNAME:-pimediasync}
echo "Setting HOSTNAME to ${PIHOSTNAME}"
echo ${PIHOSTNAME} > /etc/hostname

# Install apt requirements
apt-get update
apt-get install --no-install-recommends -y \
    git \
    vim \
    omxplayer \
    python3 \
    python3-pip \
    python3-dbus \
    python3-setuptools
apt-get clean

# download pimediasync git repo
PIMEDIASYNC_VERSION=${PIMEDIASYNC_VERSION:-master}
if [ -d ${WORKDIR}/.git ]; then
    cd ${WORKDIR}
    git fetch
    git checkout ${PIMEDIASYNC_VERSION}
    git pull
else
    git clone --branch ${PIMEDIASYNC_VERSION} --single-branch https://github.com/${GITHUB_HOST}/pimediasync ${WORKDIR}
fi

# enable app
chmod +x ${WORKDIR}/app.py

# install python requirements
PYSIMPLEDMX_VERSION='v0.2.0'
pip3 install git+https://github.com/limbicmedia/pySimpleDMX.git@${PYSIMPLEDMX_VERSION}
pip3 install -r ${WORKDIR}/requirements.txt

# systemd setup
APPLICATION_FLAGS=${APPLICATION_FLAGS:--c${WORKDIR}/example_config.py}
echo "APPLICATION_FLAGS=${APPLICATION_FLAGS}" > /etc/pimediasync.conf # setup pimediasync config file
systemctl enable ${WORKDIR}/scripts/pimediasync.service

# adjust display settings
echo 'hdmi_force_hotplug=1' >> /boot/config.txt # hdmi mode even if no hdmi monitor is detected
echo 'hdmi_drive=2' >> /boot/config.txt # normal hdmi mode
echo 'hdmi_mode=16' >> /boot/config.txt # always 1080p hdmi output

# set up tmpfs filesystem for log (protect the sd card)
if [ -z ${DEBUG} ]; then 
    echo 'tmpfs    /var/log    tmpfs    defaults,noatime,nosuid,mode=0755,size=100m    0    0' >> /etc/fstab
fi

set +e
