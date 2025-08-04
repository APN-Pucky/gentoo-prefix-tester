#!/bin/bash
# Identify if we need to run apt, dnf or yum
if command -v dnf &> /dev/null; then
    echo "Using DNF package manager"
    # install sudo
    sudo dnf install -y sudo
    source "$(dirname "$0")/bootstrap-dnf.sh"
elif command -v apt-get &> /dev/null; then
    echo "Using APT package manager"
    # install sudo
    sudo apt-get install -y sudo
    source "$(dirname "$0")/bootstrap-apt.sh"
elif command -v yum &> /dev/null; then
    echo "Using YUM package manager"
    # install sudo
    sudo yum install -y sudo
    source "$(dirname "$0")/bootstrap-yum.sh"
else
    echo "No supported package manager found. Please install build tools manually."
fi