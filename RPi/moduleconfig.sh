#!/bin/bash

# (c) Sujay Phadke, 2015.

CFGFILE="/boot/config.txt"

# Note: These must be in single quotes for multiple words to be treated as a single
# argument when passed as part of a array to a bash command. 
# see this: http://stackoverflow.com/questions/30146241/error-with-linux-whiptail-dialog?noredirect=1#comment48401487_30146241
moduleNames=('dtoverlay=w1-gpio' 'dtparam=spi' 'dtparam=i2c_arm' 'max_usb_current' 'start_x' 'hdmi_force_hotplug' 'hdmi_safe' 'disable_overscan')
moduleDesc=('1-wire interface' 'SPI Interface' 'I2C Interface' 'Increase Max USB current to 1.2Amp' 'Camera' 'Force HMDI output instead of composite' 'Override HMDI safe mode' 'Disable display overscan')
numModules=${#moduleNames[@]}
choices=("OFF" "ON")

# Check root permissions
if [[ $(id -u) -ne 0 ]]; 
then 
  echo -e "Please run with superuser (root) privileges."
  exit 1
fi

if ! [[ -f $CFGFILE ]];
then
	echo -e "Cannot read config file: $CFGFILE"
	exit 1
fi

i=0
moduleStatus=()
foundModules=0
for m in ${moduleNames[@]}
do
  # check if modules present
  p=$(grep -c "$m" $CFGFILE)
  if [[ $p > 1 ]];
  then
    echo -e "Warning: multiple lines found for module '$m'. Ignoring."
    # set p=0 to ignore the module in the next if statement
    p=0
  fi
  
  if [[ $p == 0 ]];
  then
    moduleStatus[$i]='-1'
  else
    # get status of modules by looking at names at start of a line
    moduleStatus[$i]=$(grep -c "^$m" $CFGFILE)
    ((foundModules++))
  fi
  ((i++))
done

CHECKLIST=()
if [[ $foundModules == 0 ]];
then
  whiptail --title "Error" --msgbox "No modules found." 8 40
  exit 1
else
  for ((i=0; i<$numModules; i++))
  do
    s=${moduleStatus[$i]}
    if [[ $s == -1 ]];
    then
      continue
    else
      # When extending the array, the array name must also be double-quoted. Stupid bash!
      CHECKLIST=( "${CHECKLIST[@]}" M$i "${moduleDesc[$i]}" ${choices[$s]} )
    fi
  done
  
  # The quotes around CHECKLIST are required. stupid bash again!
  # If whiptail is replaced with dialog, remove ok-button which is incompatible
  RESULT=$(whiptail \
            --title "Config Modules State" \
            --checklist --separate-output \
            --ok-button "Done" \
            "Choose modules to activate" \
            20 50 $foundModules \
            "${CHECKLIST[@]}" \
            3>&1 1>&2 2>&3)

fi

# Check if cancel pressed
if [[ $? != 0 ]];
then
  exit 1
fi

newModuleStatus=()
# note: even if a module is not present, this array will contain a '0' for it.
# this is checked later on by iterating over the original moduleStatus array
for ((i=0;i<$numModules; i++))
do
  newModuleStatus[$i]='0'
done

for i in ${RESULT[@]}
do
  # bash sub-string removal: http://stackoverflow.com/questions/2059794/what-is-the-meaning-of-the-0-syntax-with-variable-braces-and-hash-chara
  # get to-be-active module number, remove 'M' from the whiptail tags
  m=${i##M}
  newModuleStatus[$m]='1'
done

#echo ${moduleStatus[@]}
#echo ${newModuleStatus[@]}

CFGFILEBAK=$CFGFILE".bak"
sudo cp $CFGFILE $CFGFILEBAK

numChanges=0
for ((i=0; i<$numModules; i++))
do
  orig=${moduleStatus[$i]}
  new=${newModuleStatus[$i]}
  
  # Skip if module not present
  if [[ $orig == '-1' ]];
  then
    continue
  fi
  
  # no change
  if [[ $orig == $new ]];
  then
    continue
  fi
  
  # Implement changes
  case $new in
  "0")
    echo -e "Disabling module: ${moduleDesc[$i]}"
    sudo perl -i -pe "s/^${moduleNames[$i]}/#${moduleNames[$i]}/" $CFGFILE
    ;;
    
  "1")
    echo -e "Enabling module: ${moduleDesc[$i]}"
    sudo perl -i -pe "s/^(#+)${moduleNames[$i]}/${moduleNames[$i]}/" $CFGFILE
    ;;
  
  *)
    echo -e "Script Panic! Reverting from backup file."
    sudo mv $CFGFILEBAK $CFGFILE
    exit 1
  esac
  
  ((numChanges++))
done

if [[ $numChanges == 0 ]];
then
  echo -e "No changes :)"
  sudo rm $CFGFILEBAK
  exit 0
fi

echo
echo -e "Done with changes. Backup kept in file: $CFGFILEBAK"
echo -e "Reboot system for changes to take place."
exit 0
