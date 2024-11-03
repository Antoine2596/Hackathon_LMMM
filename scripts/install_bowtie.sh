#!/bin/bash

pip3 install --upgrade pip
pip3 install damona
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc

if [ ! -f  "~/.config/damona/damona.sh" ] ; then
        source ~/.config/damona/damona.sh
    fi

source ~/.bashrc

damona
