#!/bin/bash
#Environment
export LD_LIBRARY_PATH=`pwd`/tools/linux/lib/x86_64-linux-gnu/:`pwd`/tools/linux/lib/lib32/
PATH=`pwd`/tools/linux:$PATH
SERVER_DAYLIBUILD_PATH="//10.148.67.23/dailybuild"

#Temp files
RESULT_FILE=$HOME/.result
USERNAME_CACHE_FILE=$HOME/.username
AUTHENTICATE_RESULT_FILE=$HOME/.AUTHENTICATE
RELEASE_IMAGES_LIST=release_images_list.config
DEFALUT_IMAGES_LIST=`pwd`/tools/linux/default_release_images_list.config
authen_user_tool=`pwd`/tools/linux/authen_user.php

#Tool Style
TOOL_NAME="LeEco Flash Tool"
width=58
height=15
line_num=5
VERSION="V1.1"
AUTHOR="ganshuyu@le.com"
DATE="2016-12-28"

#global vars
menu_result=""
authen_result=""
keep_userdata="false"
user_name=""
pass_word=""
images_list=""
partitions_list=""
miss_files_list=""
dailybuild_root="/mnt/dailybuild"
sudo_passwd=""

function clear_exit() {
    rm -rf $RESULT_FILE
    rm -rf $AUTHENTICATE_RESULT_FILE

    clear
    exit
}

function show_pausebox() {
    str=$1
    blank_pace=""
    #count blank num
    ((blank_num=$width-${#str}))
    ((blank_num=$blank_num/2))
    for ((i=2; i<$blank_num; i++)); do
        blank_pace="$blank_pace "
    done
    str="$blank_pace$1"

    if [ "$3" = "" ]; then
        dialog --title "$TOOL_NAME" --pause \
              "\n\n\n\n\n$str" $height $width $2
    else
        dialog --title "$TOOL_NAME" $3 --pause \
              "\n\n\n\n\n$str" $height $width $2
    fi
}

function show_msgbox() {
    str=$1
    blank_pace=""
    #count blank num
    ((blank_num=$width-${#str}))
    ((blank_num=$blank_num/2))
    for ((i=2; i<$blank_num; i++)); do
        blank_pace="$blank_pace "
    done
    str="$blank_pace$1"

    if [ "$2" = "" ]; then
        dialog --title "$TOOL_NAME" --msgbox \
              "\n\n\n\n\n$str" $height $width
    else
        dialog --title "$TOOL_NAME" $2 --msgbox \
              "\n\n\n\n\n$str" $height $width
    fi
}

function show_infobox() {
    str=$1
    blank_pace=""
    #count blank num
    ((blank_num=$width-${#str}))
    ((blank_num=$blank_num/2))
    for ((i=2; i<$blank_num; i++)); do
        blank_pace="$blank_pace "
    done
    str="$blank_pace$1"

    dialog --title "$TOOL_NAME" --infobox \
              "\n\n\n\n\n$str" $height $width
}

function show_yesno() {
    str=$1
    blank_pace=""
    #count blank num
    ((blank_num=$width-${#str}))
    ((blank_num=$blank_num/2))
    for ((i=2; i<$blank_num; i++)); do
        blank_pace="$blank_pace "
    done
    str="$blank_pace$1"

    if [ "$2" = "" ];then
        dialog --title "$TOOL_NAME" --colors --yesno  \
              "\n\n\n\n\n$str" $height $width
    else
        dialog --title "$TOOL_NAME" "$2" --colors --yesno  \
              "\n\n\n\n\n$str" $height $width
    fi
}

function show_countdown_infobox() {
    count=$(($2+1))
    while [ $count -ne 0 ]; do
        time=$(($count-1))
        if [ $time -gt 1 ];then
            time="$time seconds"
        else
            time="$time second"
        fi
        show_infobox "$1 $time"
        sleep 1
        let count=count-1
    done
}

function get_authentic_string_from_server() {
    ret=-1
    #get username in cache file.
    if [ ! -f "$USERNAME_CACHE_FILE" ]; then
      echo "First time flash."
    else
      user_name=`cat $USERNAME_CACHE_FILE` 1>/dev/null 2>/dev/null
    fi

    #Get username.
    dialog --title "$TOOL_NAME" --inputbox \
        "\n\n\nPlease input your Email name (without @le.com):" $height $width $user_name 2>$USERNAME_CACHE_FILE
    if [ $? -ne 0 ]; then
        clear_exit
    fi

    user_name=`cat $USERNAME_CACHE_FILE` 1>/dev/null 2>/dev/null

    #Get password
    dialog  --title  "$TOOL_NAME"  --insecure  --passwordbox \
      "\n\n\nPlease input your Email password:" $height $width 2>$RESULT_FILE
    if [ $? -ne 0 ]; then
        clear_exit
    fi

    pass_word=`cat $RESULT_FILE`
    rm $RESULT_FILE -rf

    if [ "$user_name" = "" ] || [ "$pass_word" = "" ]; then
        authen_result=-1
    else
        show_infobox "Checking username and password..."
        #authenticate
        php $authen_user_tool $user_name $pass_word $1 1>$AUTHENTICATE_RESULT_FILE
        cat $AUTHENTICATE_RESULT_FILE | grep "timed out" 1>/dev/null 2>/dev/null
        if [ $? -eq 0 ]; then
            show_infobox "Time out. Please check the network!"
            sleep 5
            clear_exit
        fi
        cat $AUTHENTICATE_RESULT_FILE | grep "ret=" 1>$RESULT_FILE
        authen_result=`cat $RESULT_FILE`
        authen_result=${authen_result#*ret=}
    fi

    if [ $authen_result -ne 0 ]; then
        show_yesno "\Z5Username or Password ERROR! Try it again?"
        if [ $? -ne 1 ]; then
            get_authentic_string_from_server $1
        else
            clear_exit
        fi
    else
        ret=0
    fi

    return $ret
}

function enter_fastboot_mode() {
    status=0 #no devices
    adb devices | grep -w device  1>/dev/null 2>/dev/null
    if [ $? -eq 0 ]; then
        status=1
    fi

    adb devices | grep -w unauthorized  1>/dev/null 2>/dev/null
    if [ $? -eq 0 ]; then
        status=2
    fi

    fastboot devices | grep -w permissions 1>/dev/null 2>/dev/null
    if [ $? -eq 0 ]; then
        status=3
    else
        fastboot devices | grep -w fastboot 1>/dev/null 2>/dev/null
        if [ $? -eq 0 ]; then
            status=4
        fi
    fi

    case $status in
        0)
          show_infobox "Waiting the device..."
          sleep 2
          enter_fastboot_mode
        ;;

        1)
          show_countdown_infobox "Reboot to fastboot mode in" 3
          adb reboot bootloader 1>/dev/null 2>/dev/null
          enter_fastboot_mode
        ;;

        2)
          show_msgbox "Please touch the screen and allow to connect adb!"
          sleep 5
          enter_fastboot_mode
        ;;

        3)
          show_msgbox "No permissions! Please check /etc/udev/rules.d"
          clear_exit
        ;;
    esac
}

function get_default_images_list() {
    step=0
    index=0
    if [  ! -f "$RELEASE_IMAGES_LIST" ]; then
      dialog --title "$TOOL_NAME" --colors --yesno \
          "\n\n\n\Z5     Error: Not found $RELEASE_IMAGES_LIST!\
           \n\n             Use this default images list?\
           \n\n   ./tools/linux/default_release_images_list.config" $height $width
      if [ $? -ne 0 ]; then
          clear_exit
      else
          RELEASE_IMAGES_LIST="$DEFALUT_IMAGES_LIST"
      fi
    fi

    while read line
    do
    {
        if [ -n "$line" ]; then
            #echo "$line"
            case $step in
              0) #Reay
                if [ "$line" = "#IMAGES" ];then
                    step=1
                fi
                ;;
              1) #Read images name
                if [ "$line" = "#PARTITIONS" ];then
                    step=2
                    index=0
                else
                    #echo "index:$index   $line"
                    images_list[index]="$line"
                    let index=index+1
                fi
                ;;
              2) #Read partitions name
                #echo "partitions_list:$index   $line"
                partitions_list[index]="$line"
                let index=index+1
                ;;
            esac
        fi
    }
    done < $RELEASE_IMAGES_LIST

    images_num=${#images_list[@]}
    partitions_num=${#partitions_list[@]}
    if [ $images_num -ne $partitions_num ]; then
        show_msgbox "Error: images_list and partitions_list NOT MATCH."
        clear_exit
    fi
}

function remove_empty_element() {
    index=0
    images_list_temp=""
    partitions_list_temp=""

    for ((i=0; i<${#images_list[@]}; i++)); do
        if [ "${images_list[i]}" != "" ]; then
            images_list_temp[$index]=${images_list[i]}
            partitions_list_temp[$index]=${partitions_list[i]}
            let index=index+1
        fi
    done

    index=0
    unset images_list
    unset partitions_list

    for ((i=0; i<${#images_list_temp[@]}; i++)); do
        images_list[index]=${images_list_temp[i]}
        partitions_list[index]=${partitions_list_temp[i]}
        let index=index+1
    done
}

function check_files() {
    exist_flag=0
    index=0
    for ((i=0; i<${#images_list[@]}; i++));do
        ls ${images_list[i]} 1>/dev/null 2>/dev/null
        if [ $? -ne 0 ]; then
            #Check repeat
            for ((j=0; j<${#miss_files_list[@]}; j++));do
                if [ "${images_list[i]}" = "${miss_files_list[j]}" ]; then
                    exist_flag=1

                    #Remove from source
                    images_list[i]=""
                    partitions_list[i]=""
                fi
            done

            if [ $exist_flag -eq 0 ]; then
                miss_files_list[index]=${images_list[i]}
                let index=index+1

                #Remove from source
                images_list[i]=""
                partitions_list[i]=""
            else
                exist_flag=0
            fi
        fi
    done

    if [ ${#miss_files_list[0]} -ne 0 ]; then
      show_yesno "Warning: Missing ${#miss_files_list[@]} images! Continue?"
      if [ $? -ne 0 ]; then
        clear_exit
      fi
    fi

    show_pausebox "Format/erase userdata?" 5 "--cancel-label No"
    #Remove userdata.img from the list
    if [ $? -ne 0 ]; then
        keep_userdata="true"
        for ((i=0; i<${#images_list[@]}; i++));do
            if [ "${images_list[i]}" = "userdata.img" ]; then
                images_list[i]=""
                partitions_list[i]=""
                break
            fi
        done
    fi

    #Remove the empty element from list
    remove_empty_element

    if [ ${#images_list[0]} -eq 0 ]; then
        show_msgbox "Nothing to be flashed. Exit..."
        clear_exit
    fi
}

function get_random(){
    ret=1
    fastboot oem gen-verify-serial 2>$RESULT_FILE
    grep "OKAY" $RESULT_FILE  1>/dev/null 2>/dev/null
    if [ $? -eq 0 ]; then
        random=$(grep "flag" $RESULT_FILE)
        random=${random%flag*}
        random=${random#*flag}
        echo $random > $RESULT_FILE
        ret=0
    fi

    return $ret
}

function authentic_user_on_device(){
    ret=0
    #To be remove begin
    version=0

    fastboot oem device-info 2>$RESULT_FILE
    grep "version:" $RESULT_FILE 1>/dev/null 2>/dev/null
    if [ $? -eq 0 ]; then
        version=1
    fi

    echo "" > $RESULT_FILE
    while read line
    do {
        if [ "$line" != "ret=0" ]; then
            if [ $version -eq 0 ]; then #To be remove.
                fastboot oem verify-unlock$line 2>>$RESULT_FILE
            else
                fastboot oem authenticate$line 2>>$RESULT_FILE
            fi
        fi
    } done <$AUTHENTICATE_RESULT_FILE
    grep "FAILED" $RESULT_FILE 1>/dev/null 2>/dev/null
    if [ $? -eq 0 ]; then
        cat $RESULT_FILE
        ret=1
    fi

    return $ret
}

function authentic_user(){
    ret=0
    get_random
    if [ $? -eq 0 ]; then
        random=`cat $RESULT_FILE`
        get_authentic_string_from_server $random
        if [ $? -eq 0 ]; then
            authentic_user_on_device
            ret=$?
        fi
    fi

    return $ret
}

function unlocked_aboot() {
    ret=0

    fastboot oem device-info 2>$RESULT_FILE
    grep "Device unlocked: true" $RESULT_FILE 1>/dev/null 2>/dev/null
    if [ $? -ne 0 ]; then #Device is locked.
        authentic_user
        ret=$?
    fi

    if [ $ret -eq 0 ]; then
        fastboot oem enable-flash 1>/dev/null 2>/dev/null
        fastboot oem unlock-go 1>/dev/null 2>/dev/null
        fastboot flashing unlock_critical 1>/dev/null 2>/dev/null
    fi

    return $ret
}

function flash_images() {
    unlocked_aboot
    if [ $? -ne 0 ]; then
        clear_exit
    fi

    fastboot oem unlock-go  1>/dev/null 2>/dev/null
    fastboot flashing unlock_critical  1>/dev/null 2>/dev/null

    echo "">$RESULT_FILE
    for ((i=0; i<=${#images_list[@]}; i++));do
        #Show percent
        doing="\n               Flashing ${images_list[i]} ..."
        proccess="\n\n$(cat "$RESULT_FILE")\n"
        ((percent=i*100/${#images_list[@]}))

        echo $percent | dialog --title "$TOOL_NAME" \
                        --gauge "$doing$proccess" $height $width

        #Show 100% here
        if [ $i -eq ${#images_list[@]} ]; then
            sleep 2
            break
        fi

        #Flashing here!
        fastboot flash ${partitions_list[i]} ${images_list[i]}  1>/dev/null 2>/dev/null
        if [ $? -ne 0 ];then
            i_bak=$i
            show_yesno "Error: flashing <${images_list[i]}> fail! Continue?"
            if [ $? -ne 0 ]; then
                clear_exit
            fi
            i=$i_bak
        else
            echo "${partitions_list[i]}" >> $RESULT_FILE
        fi
    done

    fastboot erase ddr  1>/dev/null 2>/dev/null
    fastboot erase rootconfig  1>/dev/null 2>/dev/null

    if [ "$keep_userdata" != "true" ]; then
        show_infobox "Erasing userdata ..."
        fastboot erase userdata  1>/dev/null 2>/dev/null
        fastboot format -u userdata  1>/dev/null 2>/dev/null
    fi

    fastboot oem lock-go  1>/dev/null 2>/dev/null
    fastboot flashing lock_critical  1>/dev/null 2>/dev/null

    show_countdown_infobox "Complete. Reboot in" 3
    fastboot reboot  1>/dev/null 2>/dev/null
}

function get_sudo_password() {
    error_str=""
    if [ "$1" = "show_error" ]; then
        error_str="\Z5 ERROR! Try it again..."
    fi

    dialog  --title  "$TOOL_NAME"  --insecure --colors --passwordbox \
          "\n\n\n Input sudo password: $error_str" $height $width 2>$RESULT_FILE
    if [ $? -ne 0 ]; then
        clear_exit
    fi
    sudo_passwd=`cat $RESULT_FILE`

    if [ "$sudo_passwd" = "" ]; then
        get_sudo_password "show_error"
    fi
}

function mount_dailybuild() {
    error_str=""
    test -d $dailybuild_root
    ret=$?

    #mkdir $dailybuild_root
    while [ $ret -ne 0 ]; do
        get_sudo_password $error_str
        echo "$sudo_passwd" | sudo -S mkdir $dailybuild_root 1>/dev/null 2>/dev/null
        ret=$?

        if [ $ret -ne 0 ]; then
            error_str="show_error"
        fi
    done

    #Check dailybuild dir is empty or not.
    ls $dailybuild_root | wc -l >$RESULT_FILE
    file_num=`cat $RESULT_FILE`

    #mount dailybuild
    if [ "$file_num" = "0" ]; then
        ret=1
        error_str=""
        while [ $ret -ne 0 ]; do
            if [ "$sudo_passwd" = "" ]; then
                get_sudo_password $error_str
            fi

            echo "$sudo_passwd" | sudo -S mount -o guest -t cifs $SERVER_DAYLIBUILD_PATH $dailybuild_root 2>$RESULT_FILE
            ret=$?
            cat $RESULT_FILE | grep "wrong fs type"
            if [ $? -eq 0 ]; then
                dialog --title "$TOOL_NAME" "--no-cancel" --msgbox \
                    "\n                    Mount fail!
                    \n\n\n   Please install cifs-utils first:\
                    \n\n\n          sudo apt-get install cifs-utils" $height $width
                clear_exit
            fi

            if [ $ret -ne 0 ]; then
                sudo_passwd=""
                error_str="show_error"
            fi
        done
    fi
}

function goto_release_dir()
{
    ret=1
    dir="$dailybuild_root/"
    dialog --title "$TOOL_NAME" "--no-cancel" --msgbox \
        "\n\n   Usage:\
         \n\n         \"↑\" and \"↓\"    -- Move the cursor.\
         \n\n          \"Spacebar\"    -- Select the directory. \
         \n\n          \"/\"           -- Goto sub directory.
        " $height $width

    while [ $ret -ne 0 ]; do
        dialog --title  "$TOOL_NAME" --dselect $dir $height $width 2>$RESULT_FILE
        if [ $? -ne 0 ]; then
            clear_exit
        fi
        dir=`cat $RESULT_FILE`
        cd $dir
        ls | grep ".img" 1>/dev/null 2>/dev/null
        ret=$?

        if [ $ret -ne 0 ]; then
            show_msgbox "Not found any imges. Please select again..." "--no-cancel"
        fi
    done
}

function unlock_fastboot_only(){
    enter_fastboot_mode
    unlocked_aboot
    if [ $? -ne 0 ]; then
        show_msgbox "Unlock fastboot fail!" "--no-cancel"
    else
        show_msgbox "Success! You can run : fastboot flash NOW!"
    fi
}

function disable_system_protection(){
    enter_fastboot_mode
    authentic_user

    fastboot oem disable-verity 2>$RESULT_FILE
    grep "FAILED" $RESULT_FILE 1>/dev/null 2>/dev/null
    if [ $? -eq 0 ]; then
        show_msgbox "Disable system protection fail!" "--no-cancel"
    else
        show_countdown_infobox "Success! Reboot system in" 3
        fastboot reboot 1>/dev/null 2>/dev/null
    fi
}

function start_to_work() {
    case $1 in
      1)
        get_default_images_list
        check_files
        enter_fastboot_mode
        flash_images
        ;;

      2)
        mount_dailybuild
        goto_release_dir
        start_to_work 1
      ;;

      3)
        disable_system_protection
      ;;

      4)
        unlock_fastboot_only
      ;;

      5)
        dialog --title "$TOOL_NAME" --no-cancel --msgbox \
            "\n\n\n                 Version: $VERSION\
             \n\n                 Author: $AUTHOR\
             \n\n                 Date: $DATE " $height $width
        if [ $? -eq 0 ]; then
            main
        fi
      ;;
    esac
}

function show_menu() {
    dialog --title "$TOOL_NAME" --clear --menu "\n\n Choose one" $height $width $line_num \
      \[1\] "Flash all images" \
      \[2\] "Flash all images online" \
      \[3\] "Disable system protection" \
      \[4\] "Unlock fastboot only" \
      \[5\] "About" 2>$RESULT_FILE
    if [ 0 -ne $? ]; then
        echo "Exit"
        clear_exit
    fi
    menu_result=`cat $RESULT_FILE`
    #Delete "[]"
    menu_result=${menu_result#*[}
    menu_result=${menu_result%]*}
}

function main() {
    show_menu
    start_to_work $menu_result
    clear_exit
}

main

