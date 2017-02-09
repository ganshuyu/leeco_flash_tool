#!/bin/bash
mypath=$(cygpath -w /bin)
mypath=${mypath//\\/\/}
mypath=$(echo $mypath | sed 's/://g')
mypath=${mypath%%tools*}

#get username and password from parameters
username=""
passwd=""
if [ -f .username ]; then
    username=`cat ./.username`
fi

if [ -f .username ]; then
    passwd=`cat ./.passwd`
fi
rm -f .username .passwd

cd "/cygdrive/$mypath"
./leeco_mobile_flash.sh "$username" "$passwd"
if read -t 3 -p "Exit..." choice
then
    if [ "$choice"t = ""t ]; then
        exit
    fi
    echo ""
else
    exit
fi
