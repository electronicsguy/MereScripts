#!/bin/bash

# (C) Sujay Phadke 2015

CANCEL=0
if [[ $# == 0 ]];
then
    while [[ true ]];
    do
      IP=$(whiptail --title "IP Address Lookup" --inputbox "Please enter a valid IP or\nLeave blank for current IP." 8 40 3>&1 1>&2 2>&3)

      if [[ ($? != 0) ]];
      then
        CANCEL=1
        break
      fi

      if [[ $IP == '' ]];
      then
        break
      fi

      if [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]];
      then
        break
      fi
   done
else
	IP=$1
fi

if [[ $CANCEL != 0 ]];
then
  exit 1
fi

LOC=$(curl -s ipinfo.io/${IP})
LOC=$(echo $LOC | perl -pe 's/[{}]//g')		# remove the two curly braces
LOC=$(echo $LOC | perl -pe 's/"//g')		# remove the quotes
LOC=$(echo $LOC | perl -pe 's/, (\w+)?:/\\n$1:/g')		# remove the trailing ", " and add a newline

whiptail --title "Location of IP" --msgbox "$LOC" 20 50

echo -e $LOC
