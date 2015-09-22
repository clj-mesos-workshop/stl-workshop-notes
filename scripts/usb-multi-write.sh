#!/bin/bash
NAME='(0x1f75|0x058f|0xabcd|0x2516)'
ISO=$HOME/Desktop/STL15Mesos.iso

list_disks(){
    echo $(system_profiler SPUSBDataType | egrep -A11 $1 | perl -lne 'print $1 if /BSD Name: (.+)/' | sort)
}

get_mountpoint(){
    diskutil info $1 | grep 'Mount Point' | cut -d':' -f2- | awk '{gsub(/^ +| +$/,"")}1'
}

execute(){
    name=$1
    iso=$2
    disks=$(list_disks $1)
    echo $name $iso $disks
    for disk in $disks; do
        RAWDISK_PATH=/dev/r$disk
        DISK_PATH=/dev/$disk
        echo "/dev/$disk" >> $HOME/usb-write.log
        echo $(system_profiler SPUSBDataType | egrep -B11 $disk) >> $HOME/usb-write.log
        echo "Unmounting disk $DISK_PATH"
        diskutil unmountDisk $DISK_PATH
        echo "Started writing at " $(date +%c) >> $HOME/usb-write.log
        (time sudo dd if=$iso of=$RAWDISK_PATH bs=4194304)  2>> $HOME/usb-write.log
        echo "Ended writing at " $(date +%c) >> $HOME/usb-write.log
        sleep 3
        diskutil mountDisk $DISK_PATH
        sleep 3
        MOUNTPOINT="$(get_mountpoint $DISK_PATH)"
        echo "Opening "$MOUNTPOINT
        cd "${MOUNTPOINT}"
        echo "At" $CWD
        make validate-installers
        if [ "$?" = "0" ]; then
            echo "Installation Media is valid" >> $HOME/usb-write.log
            cd -
            echo "At $CWD"
            echo "Unmounting Disk at $DISK_PATH"
            diskutil unmountDisk $DISK_PATH
        else
            echo "Installation Media is invalid" >> $HOME/usb-write.log
            cd -
        fi
    done
}

usage(){
    echo "$0 -r <DEVICE_REGEX> -i <ISO> -x "
    exit 1
}

while getopts lher:i:x o
do	case "$o" in
	    h) usage;
               exit 1;
               ;;
            r)
                NAME=$OPTARG;
                ;;
            i)
                ISO=$OPTARG;
                ;;
            l) list_disks $NAME;
               exit 0;
               ;;
            x) execute $NAME $ISO;
               ;;
	    [?]) usage;
		 exit 1;
                 ;;
	esac
done
shift $((OPTIND-1))
