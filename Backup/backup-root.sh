#!/bin/bash
# Copyright (C) Sujay Phadke, 2015

SOURCE="/"
DEST="/media/root/"
DESTMOUNTDEV="/dev/mmcblk0p6"
DESTMOUNTDIR="/media/root"
EXCLUDE="/home/pi/Utils/Backup/rsync-root.exclude"
LOGFILE="/home/pi/Utils/Backup/rsync.log"

# Check if backup device is already mounted
sudo mountpoint -q $DESTMOUNTDIR
MOUNTED=$?

# Check if partition is mounted. "0" means Yes.
if (( $MOUNTED == 0 ));
then
  echo -e "$DESTMOUNTDEV already mounted. Continuing with backup ...\n"
else

  if [[ (-n $1) && ($1 == "auto") ]];
  then
    # Automount partition
    sudo mount $DESTMOUNTDEV $DESTMOUNTDIR
    if (( $? != 0 )) ;
    then
      echo -e "Error! : Cannot mount $DESTMOUNTDEV for backup. Exiting.\n"
      exit 1
    fi
    
  else
    echo -e "Partition '$DESTMOUNTDEV' is not mounted at '$DESTMOUNTDIR'!"
    echo -e "Use automount if necessary.\n"
    exit 1
  fi

fi

if ! [[ -d $DEST ]];
then
    echo -e "The destination directory '$DEST' doesn't exist. Verify permissions."
    echo -e "If this is the first backup, uncomment the 'exit' statement below.\n"
    exit 1
fi

# Perform differential sync
sudo rsync -avuh --delete --stats --log-file=$LOGFILE --exclude-from $EXCLUDE $SOURCE $DEST

if (( $MOUNTED == 0 ));
then
  echo -e "\nFinished backup. Leaving $DESTMOUNTDEV mounted.\n"
  exit 0
else
  # auto unmount
  sudo umount $DESTMOUNTDIR
  if (( $? != 0 )) ;
  then
    echo -e "Error! : Cannot unmount $DESTMOUNTDIR.\n"
    exit 1
  fi
fi

exit 0
