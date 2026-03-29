#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

sudo apt update

if ! command -v docker &> /dev/null; then
    sudo apt install -y docker.io
fi

if ! command -v docker-compose &> /dev/null; then
    sudo apt install -y docker-compose
fi

if ! command -v python3 &> /dev/null; then
    sudo apt install -y python3
fi
if ! command -v pip3 &> /dev/null; then
    sudo apt install -y python3-pip
fi

if ! pip3 show django > /dev/null; then
    pip3 install django
fi