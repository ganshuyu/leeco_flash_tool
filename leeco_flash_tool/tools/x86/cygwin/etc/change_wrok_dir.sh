#!/bin/bash
mypath=$(cygpath -w /bin)
mypath=${mypath//\\/\/}
mypath=$(echo $mypath | sed 's/://g')
mypath=${mypath%%tools*}
cd "/cygdrive/$mypath"
./leeco_mobile_flash.sh
if read -t 3 -p "Exit..." choice
then
    if [ "$choice"t = ""t ]; then
        exit
    fi
    echo ""
else
    exit
fi
