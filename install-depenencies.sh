#!/bin/bash

sudo apt-get -qq update
sudo apt-get install -qq build-essential cmake git devscripts quilt wget libx11-xcb1 libfontconfig1 bzr pkg-config lxc-dev chrpath p7zip-full
sudo bash -c "apt-get install -qq libgl1-mesa-dev || apt-get install -qq libgl-dev"