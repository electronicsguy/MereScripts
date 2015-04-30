#!/bin/bash
# Copyright (C) Sujay Phadke, 2015

# Read partitions with "backup" in their names, if any
# ref: http://unix.stackexchange.com/questions/14165/list-partition-labels-from-the-command-line
# Bash array reference for-loop: http://www.cyberciti.biz/faq/bash-for-loop-array/

# need to use 'eval' to expand ~
# ref: http://stackoverflow.com/questions/3963716/how-to-manually-expand-a-special-variable-ex-tilde-in-bash

# Check for required packages
#P1=$(dpkg-query -l |grep -w rsync | wc -l)
#P2=$(dpkg-query -l |grep -w mount | wc -l)
#P3=$(dpkg-query -l |grep libblkid | wc -l)
#P4=$(dpkg-query -l |grep "util-linux" | wc -l)

#PTOT=$(( $P1 + $P2 + $P3 + $P4 ))

#if [[ $PTOT != 4 ]];
#then
#  echo -e "Error: Backpi needs the following packages to be installed:\n"
#  echo -e "rsync, mount, libblkid, lsblk (util-linux).\n"
#  exit 1
#fi

HOMEDIR="/home/pi"
eval homedir=$HOMEDIR
CFG_PATH=$HOMEDIR"/.backpi/"
CFG_FILE=$CFG_PATH"backpi.cfg"

# read in config file.
# give an error if it doesn't exist in the default path
if [[ -f $CFG_FILE ]];
then
  source $CFG_FILE 2>/dev/null
else
  echo -e "Error: Config file $CFG_FILE not found (or readable). Aborting.\n"
  exit 1
fi

# Config file sanity checks
if [[ (-z $EXCLUDEHOME) || (-z $EXCLUDEROOT) || (-z $DEFHOME) || (-z $DEFDESTMOUNTDIR) || (-z $LOGFILE) || (-z $DEFDESTMOUNTDEV) ]];
then
  echo -e "Error: The following variables must be specified in the config file $CFG_FILE:\n"
  echo -e "DEFHOME, DEFDESTMOUNTDIR, DEFDESTMOUNTDEV, EXCLUDEHOME, EXCLUDEROOT, LOGFILE.\n"
  echo -e "Aborting.\n"
  exit 1
fi

# If command line options are specified, both must be specified
# option 1: user: 'home' or 'root'
# option 2: mode: 'dry-run' or 'actual'
CLI=0
if ! [[ -z $1 ]];
then
  case "$1" in
  'home')
    SOURCE=$DEFHOME
    ;;
  'root')
    SOURCE="/"
    ;;
  *)
    echo -e "Error: 1st command line argument must be 'home' or 'root'. Aborting.\n"
    exit 1
    ;;
  esac
  
  if [[ -z $2 ]];
  then
    echo -e "Error: 2nd command line argument must be 'dry-run' or 'actual'. Aborting.\n"
    exit 1
  else
    case "$2" in
    'dry-run'|'dryrun')
      ACTUAL=0
      ;;
    'actual')
      ACTUAL=1
      ;;
    *)
      echo -e "Error: 2nd command line argument must be 'dry-run' or 'actual'. Aborting.\n"
      exit 1
      ;;
    esac
    
    CLI=1
    DESTMOUNTDIR=$DEFDESTMOUNTDIR
    DESTMOUNTDEV=$DEFDESTMOUNTDEV
    DEST=$DESTMOUNTDIR$SOURCE
  fi
fi

#=========================================================
# Start of big if-statement
if [[ $CLI == 0 ]];
then
  # Check if whiptail is installed
  #WHIP=$(dpkg-query -l |grep whiptail | wc -l)
  #if [[ $WHIP == 0 ]];
  #then
  #  echo -e "Error: the package 'whiptail' is not installed and is required for interactive mode.\n"
  #  echo -e "Either install the package or run Backpi in command-line only mode.\n"
  #  exit 1
  #fi

  # get root FS '/' and '/boot' device names
  EXCL_ARRAY=(`sudo lsblk  -l -n -o name,type,mountpoint |grep -v disk | grep -E "/$|/boot$" | awk '{print $1}'`)

  # Join array elements ref: http://stackoverflow.com/questions/1527049/bash-join-elements-of-an-array
  IFS="|" eval 'EXCL_LIST="${EXCL_ARRAY[*]}"'

  # add exclusions from config file
  if ! [[ -z $DEFEXCL ]];
  then
    DEFEXCL=$(echo $DEFEXCL | sed -e 's/ /|/g')
    EXCL_LIST=$EXCL_LIST"|"$DEFEXCL
  fi

  # Retrieve relevant partition names
  # Keep only slave partition names
  # Exclude non-eligible partitions
  mapfile BACKUPPARTS -t < <(sudo lsblk -l -n -o name,label,type | grep -v disk | perl -pe 's/part//g' | grep -Ev $EXCL_LIST)

  NUMPARTS=${#BACKUPPARTS[@]}

  if [[ $NUMPARTS == 0 ]];
  then
    echo -e "No valid partitions found. Specify one on the command line.\n"
    echo -e "Valid Partition names are:"
    sudo lsblk -l -n -o name,type | grep -v disk | awk '{print $1}'
    exit 1
  fi

  PARTLIST=''
  for (( i=0; i<$NUMPARTS; i++ ));
  do
    PARTLIST=$PARTLIST" "$i" "\"${BACKUPPARTS[$i]}\"
  done

  # Remove extra spaces
  PARTLIST=$(echo $PARTLIST | sed 's/ " /" /g')
  PARTLIST=$(echo $PARTLIST | sed 's/ "$/"/')

  if [[ $NUMPARTS > 10 ]];
  then
    NUMROWS=10
  else
    NUMROWS=$NUMPARTS
  fi

  # Bash parameter array for running a command
  # http://stackoverflow.com/questions/11079342/execute-command-containing-quotes-from-shell-variable
  COMMAND="whiptail --title \"Mera Backup\" --menu \"Select the destination backup partition (/, /boot, 'SETTINGS' and 'RECOVERY' partitions have been excluded)\" --cancel-button Cancel --ok-button Select --notags   20 50 $NUMROWS $PARTLIST 3>&1 1>&2 2>&3"

  OPTION=$(eval "$COMMAND")
  BUTTON=$?

  # Check if 'Cancel' or 'ESC' pressed
  if [[ ($BUTTON == 1) || ($BUTTON = 255) ]];
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
  if [[ ($PARTDESTMOUNTDIR != "") && ("$CHECKBADNAME" == "$PARTDESTMOUNTDIR") ]];
  then
    DESTMOUNTDIR="/media/"$PARTDESTMOUNTDIR
  else
    # Bad name
    DESTMOUNTDIR=''
  fi

  if [[ $DESTMOUNTDIR == "" ]];
  then
    echo -e "Destination device $DESTMOUNTDEV either doesn't have a label or "
    echo -e "the label contains special characters (mounting problems).\n"
    # Check if backup device is already mounted
    MOUNTED=$(sudo mount | grep -i $DESTMOUNTDEV)

    if [[ $MOUNTED != "" ]];
    then
      echo -e "Device $DESTMOUNTDEV is already mounted. We need to unmount it first and"
      echo -e "then re-mount it in a different directory. Would you like to proceed? (y/N):"
      read ANSWER
      if [[ ($ANSWER == "Y") || ($ANSWER == "y") ]];
      then
        sudo umount $DESTMOUNTDEV
        if [[ $? != 0 ]];
        then
          echo -e "Error: Unable to unmount device $DESTMOUNTDEV. Aborting.\n"
          exit 1
        fi
        echo -e "Unmount successful.\n"
      else
        exit 1
      fi
    fi

    # Get mount directory from user
    while true
    do
      echo -e "Please enter destination mount directory without"
      echo -e "any special characters or spaces (default: /media/root): "
      read DESTMOUNTDIR

      if [[ $DESTMOUNTDIR == "q" ]];
      then
        exit 1
      fi

      if [[ $DESTMOUNTDIR == "" ]];
      then
        DESTMOUNTDIR="/media/root"
      fi

      TEMP=$(echo $DESTMOUNTDIR | grep -i '^\/media\/')
      if [[ $TEMP == "" ]];
      then
        echo -e "Error: Destination directory must be within '/media'\n"
      else
        break
      fi
    done

  fi

  OPTION=$(whiptail --title "Mera Backup" --menu "Select the backup source" --cancel-button Cancel --ok-button Select --notags   10 50 2 0 "/home/pi/ (user: pi)" 1 "/ (entire root FS)" 3>&1 1>&2 2>&3)
  BUTTON=$?

  # Check if 'Cancel' or ESC pressed
  if [[ ($BUTTON == 1) || ($BUTTON = 255) ]];
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
  if [[ ($BUTTON == 1) || ($BUTTON = 255) ]];
  then
    exit
  fi

fi  # endif for if $CLI == 0

#=========================================================

# Check if destination mount directory exists
if ! [[ -d $DESTMOUNTDIR ]];
then
  sudo mkdir -p $DESTMOUNTDIR
  if [[ $? != 0 ]];
  then
    echo -e "Error creating mount directory $DESTMOUNTDIR. Aborting.\n"
    exit 1
  fi
fi

# Check if backup device is already mounted
sudo mountpoint -q $DESTMOUNTDIR
MOUNTED=$?

# Check if partition is mounted. "0" means Yes.
if [[ $MOUNTED == 0 ]];
then
  # Check if the correct partition is mount at that destination. If not, exit
  MOUNTEDDIR=$(sudo mount | grep "$DESTMOUNTDEV" | awk '{print $3}')
  if [[ $MOUNTEDDIR != $DESTMOUNTDIR ]];
  then
    echo -e "Error: A partition other than $DESTMOUNTDEV is mount at: $DESTMOUNTDIR.\n"
    echo -e "Please unmount this partition and try again. Aborting.\n"
    exit 1
  fi
  echo -e "$DESTMOUNTDEV already mounted at $MOUNTEDDIR. Continuing with backup ...\n"

else
    # Automount partition
    echo -e "Partition '$DESTMOUNTDEV' is not mounted at '$DESTMOUNTDIR'"
    echo -e "Automounting ...\n"

    sudo mount $DESTMOUNTDEV $DESTMOUNTDIR
    if [[ $? != 0 ]];
    then
      echo -e "Error! : Cannot mount $DESTMOUNTDEV for backup. Exiting.\n"
      exit 1
    fi
fi

if ! [[ $SOURCE == "/" ]]
then
  if ! [[ -d $DEST ]];
  then
    echo -e "The destination directory '$DEST' does not exist."
    echo -e "Looks like this is a first backup. Creating it ... \n"
    sudo mkdir -p $DEST
    if [[ $? != 0 ]]
    then
      echo -e "Error creating backup directory $DEST. Aborting.\n"
      exit 1
    fi
  fi

  EXCLUDE=$CFG_PATH$EXCLUDEHOME
else
  EXCLUDE=$CFG_PATH$EXCLUDEROOT
fi

LOGFILE=$CFG_PATH$LOGFILE

if ! [[ -f $EXCLUDE ]];
then
  echo -e "Error: rsync exclude file $EXCLUDE not found or not readable."
  echo -e "Exclude files must be present in the configuration directory, even if empty. Aborting\n"
  exit 1
fi

#echo -e "source=$SOURCE"
#echo -e "dest=$DEST"
#echo -e "destmountdev=$DESTMOUNTDEV"
#echo -e "destmountdir=$DESTMOUNTDIR"
#echo -e "logfile=$LOGFILE"
#echo -e "excludefile=$EXCLUDE"
#echo -e "actual=$ACTUAL"

# Perform sync
if [[ $ACTUAL == 0 ]]
then
  echo -e "Performing a dry run only\n"
  sudo rsync -avuPh --dry-run --delete --stats --log-file=$LOGFILE --exclude-from $EXCLUDE $SOURCE $DEST
else
  echo -e "Performing actual differential backup\n"
  sudo rsync -avuh --delete --stats --log-file=$LOGFILE --exclude-from $EXCLUDE $SOURCE $DEST
fi

if [[ $MOUNTED == 0 ]];
then
  echo -e "\nFinished backup. Leaving $DESTMOUNTDEV mounted.\n"
  exit 0
else
  # auto unmount
  sudo umount $DESTMOUNTDIR
  if [[ $? != 0 ]] ;
  then
    echo -e "Error! : Cannot unmount $DESTMOUNTDIR.\n"
    exit 1
  fi
fi

exit 0
