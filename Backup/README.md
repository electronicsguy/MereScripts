I wrote this script to simplify backing up the Raspberry Pi data. 
My current setup is as follows:

The working root filesystem is on a USB drive in my RPi.
The backup is taken on the micro-SD card.
The micro-SD card backup partition is mounted at:
 /media/root
 
 Backpi requires a working directory '.backpi' within the uesr pi's home directory.
 (Change this in the script for a different location)
 The config file (backpi.cfg) needs to be like this:
 ```
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
```
All these definitions need to be in the file, even if not used (see below).
Backpi can be used in a command-line only mode or in an interactive mode.
For the former, all the above definitions should make sense.
For the latter, only the exclude files, logfile and defexcl should make sense.

For interactive mode, simply run Backpi without any command line arguments.
For command-line only mode, run Backpi with 2 arguments:
```
./backpi.sh  <user>  <mode>
```
where <user> can be either 'home' or 'root' and
<mode> can be 'dry-run' or 'actual'
The default device and destination directories are picked up from the config file.

All this can be set manually in the interactive mode.
If Backpi runs with mode 'dry-run'. it gives a verbose output of everthing that would be done 
(copies, deletions) without actually making any changes. This is great for testing.
  
Note: the backup location must be mounted and writable (by default at: /media/root).
If not, Backpi tries to auto-mount it, or else exits with an error. 

Backpi uses the standard Linux 'rsync' command, so only the required file modifications 
and deletions will be propagated, based on modification times (a differential backup).

Even though I wrote Backpi for use with my Raspberry Pi, you could use it in any Linux system.
Also, you could automate the backup by adding it as a 'cron' job.
For example, to take a backup of the 'home' partition everyday at 9pm, put this in your root crontab:
```
0 21 * * * nice -n 15 /home/pi/backpi.sh home actual > /dev/null
```
All files distributed under that standard GPL V3 licence, unless stated otherwise.

(C) Sujay Phadke
