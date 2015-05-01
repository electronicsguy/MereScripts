#Backpi

I wrote this script to simplify backing up the Raspberry Pi data. 
My current setup is as follows:

The working root filesystem is on a USB drive in my RPi.
The backup is taken on the micro-SD card.
The micro-SD card backup partition is mounted at:
 /media/root
 
 Backpi requires a working directory '.backpi' within the uesr pi's home directory.
 (Change this in the script for a different location)
 The config file (backpi.cfg) needs to be like this:
 ```bash
# Configuration file for backpi.sh

DEFHOME="/home/pi/"
DEFDESTMOUNTDIR="/media/root"
DEFDESTMOUNTDEV="/dev/mmcblk0p7"

EXCLUDEHOME="rsync-home.exclude"
EXCLUDEROOT="rsync-root.exclude"
LOGFILE="rsync.log"

# Exclude partitions with these labels from the backup destinations
# Cannot contain spaces
DEFEXCL="SETTINGS RECOVERY"

VALIDPART="rpi-backup"
```
All the definitions (except **VALIDPART**) need to be in the config file, even if not used (see below).

Backpi can be used in a command-line only mode or in an interactive mode.

##Command-line only mode:
For command-line only mode, all variable definitions in the config file, except for **VALIDPART**
must be specified and make sense. The default source and destination paths are picked up from the config file. 
The **VALIDPART** argument is mainly to safeguard during an automated *cron* run of Backpi. If **VALIDPART** exists,
Backpi checks to make sure the **DEFDESTMOUNTDEV** is actually named as that. If not, it aborts. This protects against a
backup taken when another partition (with a different expected name) in present in the partition table at the location
given by **DEFDESTMOUNTDEV** (This is common when switching SD cards in the Raspberry Pi).

Run Backpi with 2 arguments:
```bash
./backpi.sh  <user>  <mode>
```
where `<user>` can be either 'home' or 'root' and
`<mode>` can be 'dry-run' or 'actual'

##Interactive Mode
For entering interactive mode, rn Backpi without any arguments. In this mode, Backpi uses a menu driven input to get the specifics from the user. Only the **EXCLUDEnnn**, **LOGFILE** and **DEFEXCL** variables should be making sense.

If Backpi runs in the 'dry-run' mode, it gives a verbose output of everthing that would be done 
(copies, deletions) without actually making any changes. This is great for testing.
  
**Note**: the backup location must be mounted and writable (by default at: /media/root).
If not, Backpi tries to auto-mount it and if it cannot, exits with an error. 

Backpi uses the standard Linux *rsync* command, so only the required file modifications 
and deletions will be propagated, based on modification times (a differential backup).

Even though I wrote Backpi for use with my Raspberry Pi, you could use it in any Linux system.
You could automate the backup by adding it as a *cron* job. Be sure to make use of the **VALIDPART** variable.
For example, to take a backup of the *home* partition everyday at 9pm, put this in your root crontab:
```
0 21 * * * nice -n 15 /home/pi/backpi.sh home actual > /dev/null
```
All files distributed under that standard GPL V3 licence, unless stated otherwise.

(C) Sujay Phadke, 2015.
