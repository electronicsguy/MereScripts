I wrote these scripts to simplify backing up the raspberry pi data. My current setup is as follows:

My working "/" (root) directory with the "home/pi" is on a USB drive in my RPi. The backup "/" is actually the "root" partition
 on the micro-SD card, mounted at:
 /media/root
 
 So the backup is happening as follows:
 backup-home.sh backups:
 /home/pi => /media/root/home/pi
 
 backup-root.sh backups:
 / => /media/root
 
 The files with the "-dryrun" suffix give a verbose output of everthing that would be done (copies, deletions) without actually 
  making any changes. This is good for testing.
  
Note: the backup location must be mounted and writable at: /media/root (or to another location if you appropriately modify 
 the scripts), or eles it'll exit with an error. Now this can happen the first time the scripts are run, so simply do a 
 complete backup-root for the first time by deleting the 'exit' command after the error message.

The scripts use the standard 'rsync' command, so only file modifications and deletions will be propagated (differential 
 backup).
Even though I wrote them for use in my raspberry pi, you could use them in any linux system. Also, you could automate the 
 backup by adding these as a 'cron' job.

All files distributed under that standard GPL V3 licence.
 
