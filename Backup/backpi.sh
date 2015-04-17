#!/bin/bash
# Copyright (C) Sujay Phadke, 2015

EXCLUDEHOME="/home/pi/Utils/Backup/rsync-home.exclude"
EXCLUDEROOT="/home/pi/Utils/Backup/rsync-root.exclude"
LOGFILE="/home/pi/Utils/Backup/rsync.log"

# Read partitions with "backup" in their names, if any
# ref: http://unix.stackexchange.com/questions/14165/list-partition-labels-from-the-command-line
# Bash array reference for-loop: http://www.cyberciti.biz/faq/bash-for-loop-array/

mapfile BACKUPPARTS -t < <(sudo lsblk -l -o name,label | grep -i backup | sed 's/ $//' )

# Add any partition name specified on the command line, without the "/dev/"
# ref: add values to bash array
# http://stackoverflow.com/questions/1951506/bash-add-value-to-array-without-specifying-a-key 
if [[ -n $1 ]]
then
  ARGDEV="/dev/"$1
  RET=$(sudo lsblk  --nodeps -o type $ARGDEV |grep -i part )
  
  NOEXIST=0
  if [[ $? != 0 ]]
  then
    echo -e "Error: Invalid partition name"
    NOEXIST=1
  fi
  
  if [[ $RET == '' ]]
  then
    echo -e "Error: Invalid partition name"
    NOEXIST=1    
  fi
  
  if [[ $NOEXIST != 0 ]]
  then
    echo -e "Valid Partition names are (use only inner partition names, not the main disk name):"
    sudo lsblk -l -o name
    exit 1
  fi
    
  BACKUPPARTS+=($1)
fi

NUMPARTS=${#BACKUPPARTS[@]}

if [[ $NUMPARTS == 0 ]]
then
  echo -e "No Partitions with 'backup' in the name found. Specify one on the command line.\n"
  echo -e "Valid Partition names are (use only inner partition names, not the main disk name):"
  sudo lsblk -l -o name
  exit 1
fi

PARTLIST=''
for (( i=0; i<$NUMPARTS; i++ ))
do
  PARTLIST=$PARTLIST" "$i" "\"${BACKUPPARTS[$i]}\"
done

# Remove extra spaces
PARTLIST=$(echo $PARTLIST | sed 's/ " /" /g')
PARTLIST=$(echo $PARTLIST | sed 's/ "$/"/')

if (( $NUMPARTS>10 ))
then
  NUMROWS=10
else
  NUMROWS=$NUMPARTS
fi

# Bash parameter array for running a command: 
# http://stackoverflow.com/questions/11079342/execute-command-containing-quotes-from-shell-variable
COMMAND="whiptail --title \"Mera Backup\" --menu \"Select the destination backup partition\" --cancel-button Cancel --ok-button Select --notags   10 50 $NUMROWS $PARTLIST 3>&1 1>&2 2>&3"

OPTION=$(eval "$COMMAND")
BUTTON=$?

# Check if 'Cancel' or ESC pressed
if [[ ($BUTTON == 1) || ($BUTTON = 255) ]]
then
  exit 1
fi

# get partial name of device
PARTDEV=$(echo ${BACKUPPARTS[$OPTION]} | cut -d " " -f 1)
DESTMOUNTDEV="/dev/"$PARTDEV
# Drive labels may have spaces and special characters like single-quotes in them
# That cannot be easily mounted. Instead use alternate mount directory name
# Allow dashes
PARTDESTMOUNTDIR=$(echo ${BACKUPPARTS[$OPTION]} | perl -pe 's/\w+ (.*)/$1/')
CHECKBADNAME=$(echo $PARTDESTMOUNTDIR | grep -v '[^a-zA-Z0-9-]')
if [[ ($PARTDESTMOUNTDIR != "") && ("$CHECKBADNAME" == "$PARTDESTMOUNTDIR") ]]
then
  DESTMOUNTDIR="/media/"$PARTDESTMOUNTDIR
else
  # Bad name
  DESTMOUNTDIR=''
fi

if [[ "$DESTMOUNTDIR" == "" ]]
then
  echo -e "Destination device $DESTMOUNTDEV does not have a label or has special characters.\n"
  echo "Input destination mount location (default: /media/root): "
  read DESTMOUNTDIR
  
  # detect ESC pressed in bash input:
  # http://stackoverflow.com/questions/17637591/how-to-detect-when-user-press-esc-and-do-something-in-shell-script
  if [[ ("$DESTMOUNTDIR" == $'\e') || ("$DESTMOUNTDIR" == "q") ]]
  then
    exit 1
  fi
  
  if [[ "$DESTMOUNTDIR" == "" ]]
  then
    DESTMOUNTDIR="/media/root"
  fi

fi

if ! [[ -d $DESTMOUNTDIR ]]
then
  sudo mkdir -p $DESTMOUNTDIR
  if [[ $? != 0 ]]
  then
    echo -e "Error creating mount directory $DESTMOUNTDIR. Aborting.\n"
    exit 1
  fi
fi

if [[ ("$DESTMOUNTDIR" == "/") || ("$DESTMOUNTDIR" == "$SOURCE")]]
then
  echo -e "Error: Destination directory cannot be same as source!\n"
  exit
fi

OPTION=$(whiptail --title "Mera Backup" --menu "Select the backup source" --cancel-button Cancel --ok-button Select --notags   10 50 2 0 "/home/pi/ (user: pi)" 1 "/ (entire root FS)" 3>&1 1>&2 2>&3)
BUTTON=$?

# Check if 'Cancel' or ESC pressed
if [[ ($BUTTON == 1) || ($BUTTON = 255) ]]
then
  exit
fi

case $OPTION in
0)
  SOURCE="/home/pi/"  # This termination / is essential for rsync
  DEST=$DESTMOUNTDIR$SOURCE
  ;;
1)
  SOURCE="/"
  DEST=$DESTMOUNTDIR"/"  # This termination / is essential for rsync
esac

ACTUAL=$(whiptail --title "Mera Backup" --menu "Select mode" --cancel-button Cancel --ok-button Select --notags   10 50 2 0 "dry-run" 1 "Actual" 3>&1 1>&2 2>&3)
BUTTON=$?

# Check if 'Cancel' or ESC pressed
if [[ ($BUTTON == 1) || ($BUTTON = 255) ]]
then
  exit
fi

# Check if backup device is already mounted
sudo mountpoint -q $DESTMOUNTDIR
MOUNTED=$?

# Check if partition is mounted. "0" means Yes.
if (( $MOUNTED == 0 ));
then
  echo -e "$DESTMOUNTDEV already mounted. Continuing with backup ...\n"
else
    # Automount partition
    echo -e "Partition '$DESTMOUNTDEV' is not mounted at '$DESTMOUNTDIR'"
    echo -e "Automounting ...\n"

    sudo mount $DESTMOUNTDEV $DESTMOUNTDIR
    if (( $? != 0 )) ;
    then
      echo -e "Error! : Cannot mount $DESTMOUNTDEV for backup. Exiting.\n"
      exit 1
    fi
fi

if ! [[ "$SOURCE" == "/" ]]
then
  if ! [[ -d $DEST ]];
  then
    echo -e "The destination directory '$DEST' does not exist."
    echo -e "Looks like a first backup. Creating it ... \n"
    sudo mkdir -p $DEST
    if [[ $? != 0 ]]
    then
      echo -e "Error creating backup directory $DEST. Aborting.\n"
      exit 1
    fi
  fi
  
  EXCLUDE=$EXCLUDEHOME
else
  EXCLUDE=$EXCLUDEROOT
fi

# Perform sync
if [[ $ACTUAL == 0 ]]
then
  echo -e "Performing a dry run only\n"
  sudo rsync -avuPh --dry-run --delete --stats --log-file=$LOGFILE --exclude-from $EXCLUDE $SOURCE $DEST
else
  echo -e "Performing actual differential backup\n"
  sudo rsync -avuh --delete --stats --log-file=$LOGFILE --exclude-from $EXCLUDE $SOURCE $DEST
fi

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
