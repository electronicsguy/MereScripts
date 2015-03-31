#!/bin/bash

SOURCE="/home/pi/"
DEST="/media/root/home/pi/"
DESTMOUNTDEV="/dev/mmcblk0p6"
DESTMOUNTDIR="/media/root"
EXCLUDE="/home/pi/Utils/Backup/rsync-home.exclude"
LOGFILE="/home/pi/Utils/Backup/rsync.log"

# Check if backup device is already mounted
sudo mountpoint -q $DESTMOUNTDIR
MOUNTED=$?

if (( $MOUNTED == 0 ));
then
  echo -e "$DESTMOUNTDEV already mounted. Continuing with backup ...\n"
else
  sudo mount $DESTMOUNTDEV $DESTMOUNTDIR
  if (( $? != 0 )) ;
    then
    echo -e "Error! : Cannot mount $DESTMOUNTDEV for backup. Exiting.\n"
    exit 1
  fi
fi

if ! [[ -d $DEST ]];
then
    echo -e "The destination directory '$DEST' doesn't exist or is not mounted."
    echo -e "If this is the first backup, uncomment the 'exit' below.\n"
    exit 1
fi 

sudo rsync -avuh  --delete --stats --log-file=$LOGFILE --exclude-from $EXCLUDE $SOURCE $DEST

if (( $MOUNTED == 0 ));
then
  echo -e "\nFinished. Leaving $DESTMOUNTDEV mounted.\n"
  exit 0
else
  sudo umount $DESTMOUNTDIR
  if (( $? != 0 )) ;
  then
    echo -e "Error! : Cannot unmount $DESTMOUNTDIR.\n"
    exit 1
  fi
fi

exit 0
