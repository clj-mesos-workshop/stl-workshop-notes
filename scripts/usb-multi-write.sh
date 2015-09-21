#!/bin/bash
NAME=${1:-'(0x1f75|0x058f|0xabcd|0x2516)'}
ISO=${2:-$HOME/Desktop/STL15Mesos.iso}
disks=$(system_profiler SPUSBDataType | egrep -A11 $NAME | perl -lne 'print $1 if /BSD Name: (.+)/' | sort)
for disk in $disks; do
    RAWDISK_PATH=/dev/r$disk
    DISK_PATH=/dev/$disk
    echo "/dev/$disk" >> $HOME/usb-write.log
    echo $(system_profiler SPUSBDataType | egrep -B11 $disk) >> $HOME/usb-write.log
    echo "Unmounting disk $DISK_PATH"
    diskutil unmountDisk $DISK_PATH
    echo "Started writing at " $(date +%c) >> $HOME/usb-write.log
    (time sudo dd if=$ISO of=$RAWDISK_PATH) 2>> $HOME/usb-write.log
    echo "Ended writing at " $(date +%c) >> $HOME/usb-write.log
done
