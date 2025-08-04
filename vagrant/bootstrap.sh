#!/bin/bash
# Identify if we need to run apt, dnf or yum
if command -v dnf &> /dev/null; then
    echo "Using DNF package manager"
    if command -v sudo &> /dev/null; then
        echo "Sudo is already installed"
    else
        dnf check-update
        # install sudo
        dnf install -y sudo
    fi
    source "$(dirname "$0")/bootstrap-dnf.sh"
elif command -v apt-get &> /dev/null; then
    echo "Using APT package manager"
    if command -v sudo &> /dev/null; then
        echo "Sudo is already installed"
    else
        apt-get update
        # install sudo
        apt-get install -y sudo
    fi
    source "$(dirname "$0")/bootstrap-apt.sh"
elif command -v yum &> /dev/null; then
    echo "Using YUM package manager"
    if command -v sudo &> /dev/null; then
        echo "Sudo is already installed"
    else
        # install sudo
        yum install -y sudo
    fi
    source "$(dirname "$0")/bootstrap-yum.sh"
else
    echo "No supported package manager found. Please install build tools manually."
fi