#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

echo "Starting installation of development tools..."

echo "Updating apt package index..."
sudo apt update

echo "Installing prerequisites..."
sudo apt-get install -y ca-certificates curl

if ! command -v docker &> /dev/null; then
    echo "Uninstalling all conflicting Docker packages..."
    # Using a loop to avoid "argument list too long" or empty argument errors
    for pkg in docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc; do
        sudo apt remove -y $pkg > /dev/null 2>&1 || true
    done

    # Add Docker's official GPG key:
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources (must be flush-left):
    echo "Configuring Docker repository..."
    sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    echo "Updating apt index with Docker repository..."
    sudo apt update

    echo "Installing Docker packages..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Starting Docker service..."
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo systemctl status docker --no-pager
else
    echo "Docker is already installed."
fi

echo "Adding user $USER to the docker group..."
sudo usermod -aG docker "$USER"
echo "Note: You may need to log out and log back in for the group changes to take effect."

if ! command -v python3 &> /dev/null; then
    echo "Installing python3..."
    sudo apt install -y python3
else
    echo "python3 is already installed."
fi

if ! command -v pip3 &> /dev/null; then
    echo "Installing python3-pip..."
    sudo apt install -y python3-pip
else
    echo "pip3 is already installed."
fi

if ! pip3 show django > /dev/null 2>&1; then
    echo "Installing Django..."
    pip3 install django
else
    echo "Django is already installed."
fi

echo "Installation complete!"
