#!/usr/bin/env bash

set -e

# verify that the script is run as root
if [ $(whoami) != 'root' ]; then
    echo 'Must be run as root.'
    exit 1
fi

# set the working directory and repository source
HOMEDIR=${HOMEDIR:-/opt}
WORKDIR=${PIMEDIASYNC_WORKDIR:-${HOMEDIR}/pimediasync}
PIMEDIASYNC_VERSION=${PIMEDIASYNC_VERSION:-v1.1.3}
GITHUB_HOST=${GITHUB_HOST:-limbicmedia}

# clean the working directory
rm -rf ${WORKDIR}
mkdir -p ${WORKDIR}

# install software requirements
apt update
apt install --no-install-recommends -y \
    git \
    vim \
    omxplayer \
    python3 \
    python3-pip \
    python3-dbus \
    python3-setuptools
apt clean

# clone the pimediasync git repository
git clone --branch ${PIMEDIASYNC_VERSION} --depth 1 --single-branch https://github.com/${GITHUB_HOST}/pimediasync ${WORKDIR}

# enable app
chmod +x ${WORKDIR}/app.py

# install a working version of pysimpledmx
PYSIMPLEDMX_VERSION='v0.2.0'
pip3 install git+https://github.com/limbicmedia/pySimpleDMX.git@${PYSIMPLEDMX_VERSION}

# install other dependencies
pip3 install -r ${WORKDIR}/requirements.txt

# set up the service to run the app on boot
APPLICATION_FLAGS=${APPLICATION_FLAGS:-"-c ${WORKDIR}/example_config.py"}
echo "APPLICATION_FLAGS=${APPLICATION_FLAGS}" > /etc/pimediasync.conf
systemctl enable ${WORKDIR}/scripts/pimediasync.service

# adjust display settings
echo 'hdmi_force_hotplug=1' >> /boot/config.txt # hdmi mode even if no hdmi monitor is detected
echo 'hdmi_drive=2' >> /boot/config.txt # normal hdmi mode
echo 'hdmi_mode=16' >> /boot/config.txt # always 1080p hdmi output

# set up tmpfs filesystem for logging to protect the sd card
if [ -z ${DEBUG} ]; then
    echo 'tmpfs    /var/log    tmpfs    defaults,noatime,nosuid,mode=0755,size=100m    0    0' >> /etc/fstab
fi

set +e
