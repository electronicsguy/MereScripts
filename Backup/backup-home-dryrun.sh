#!/bin/bash

SOURCE="/home/pi/"
DEST="/media/root/home/pi/"
EXCLUDE="/home/pi/Utils/backup/rsync-home.exclude"
LOGFILE="/home/pi/Utils/backup/rsync.log"

if ! [[ -w $DEST ]];
then
    echo -e "The destination directory '$DEST' either doesn't exist or isn't writable!."
    echo -e "If this is the first backup, uncomment the 'exit' below."
    exit
fi 

sudo rsync -avunPh  --delete --stats --log-file=$LOGFILE --exclude-from $EXCLUDE $SOURCE $DEST
