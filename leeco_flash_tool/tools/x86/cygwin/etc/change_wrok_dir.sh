#!/bin/bash
mypath=$(cygpath -w /bin)
mypath=${mypath//\\/\/}
mypath=$(echo $mypath | sed 's/://g')
mypath=${mypath%%tools*}
cd /cygdrive/$mypath
./leeco_mobile_flash.sh
read -p "Press enter key to exit..." choice
exit