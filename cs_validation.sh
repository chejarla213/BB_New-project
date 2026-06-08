#!/bin/bash

####################################################
#                                                  #
#     CS_Validation_Script & Auto Correction       #
#                 VERSION : 6.0                    #
#         Last Modified Date :22-MAY-2026          #
####################################################

Master_Path="/home/pi/scripts"

Clean_and_Move=$(cat $Master_Path/clean_and_move.sh | grep -i "version" | cut -d"#" -f2 | cut -d":" -f2 | cut -d"." -f1)
Monitor_Record=$(cat $Master_Path/monitor_record.sh | grep -i "version" | cut -d"#" -f2 | cut -d":" -f2 | cut -d"." -f1)
Minion_ID=$(cat /etc/salt/minion | grep id: | grep -io BB.* | tr -d ' ')
LOG="/home/pi/Desktop/${Minion_ID}"

rm /home/pi/Desktop/${Minion_ID} > /dev/null 2>&1

Success=$(echo 'Success')
Failed=$(echo 'Failed')

function debug()
{
    echo "$1" >> ${LOG}
}

Watchdog=$(cat /usr/local/bin/watchdog.sh | grep "Version" | cut -d"#" -f2 | cut -d":" -f2 | cut -d"." -f1)

if [ "$Clean_and_Move" -eq "16" ] && \
   [ "$Monitor_Record" -eq "16" ] && \
   [ "$Watchdog" -eq "6" ] && \
   [ -f $Master_Path/scirpt_video_record_stop.sh ] && \
   [ -f $Master_Path/scirpt_video_record_start.sh ] && \
   [ -f $Master_Path/upload_video.py ]; then

    debug "Latest Scripts - $Success"
    printf "\n" >> ${LOG}

else

    debug "Latest Scripts - $Failed"
    printf "\n" >> ${LOG}

fi

ALERT=85

Disk_Space=$(df -H | grep -vE 'abc:/xyz/pqr | tmpfs |cdrom|Used' | awk '{ print $5 " " $1 }' | grep -i "/dev/root" | awk '{ print $1}' | cut -d'%' -f1)

if [ "$Disk_Space" -ge "$ALERT" ]; then

	debug "Disk Alert - $Failed"
	printf "\n" >> ${LOG}

else

	debug "Disk Alert - $Success"
	printf "\n" >> ${LOG}

fi

VS_IP=$(ip route get 1 | awk '{print $7;exit}' | cut -d"." -f4)

Fixed=10

COUNT=`expr $VS_IP - $Fixed`

Actual_VS_IP="10.0.21.$COUNT"
ping -c 1 10.0.21.$COUNT &> /dev/null && debug "MAC-Binding - $Success" || debug "MAC-Binding - $Failed"
printf "\n" >> ${LOG}

BOOT_RO=$(cat /etc/fstab | grep -i "/boot" | awk '{print $4}')
USB_NOFAIL=$(cat /etc/fstab | grep -i "/media/usb" | cut -d"," -f2)

if [ "$BOOT_RO" == "ro" ] && [ "$USB_NOFAIL" == "nofail" ]; then

        debug "Fstab Entry - $Success"
        printf "\n" >> ${LOG}

else

        debug "Fstab Entry - $Failed"
        printf "\n" >> ${LOG}

fi

#######
# Cron Entry Check
Cron_Entry=$(cat /var/spool/cron/crontabs/pi | grep -c -E "clean_and_move.sh|monitor_record.sh|/media/usb/videos/|/usr/local/bin/watchdog.sh|lcd_snapshot_api.py")

# Cron Enable Check
CleanandMove=$(grep -i "clean_and_move.sh" /var/spool/cron/crontabs/pi | awk '{print $1}' | cut -b1)
Monitor=$(grep -i "monitor_record.sh" /var/spool/cron/crontabs/pi | awk '{print $1}' | cut -b1)
Watchdog=$(grep -i "/usr/local/bin/watchdog.sh" /var/spool/cron/crontabs/pi | awk '{print $1}' | cut -b1)
LCD_snapshot=$(grep -i "lcd_snapshot_api.py" /var/spool/cron/crontabs/pi | awk '{print $1}' | cut -b1)

# Cron File Permission Check
Cronfile=$(sudo stat -L -c "%a" /var/spool/cron/crontabs/pi)

if [ "$Cron_Entry" -eq "6" ] && \
   [ "$CleanandMove" != "#" ] && \
   [ "$Monitor" != "#" ] && \
   [ "$Watchdog" != "#" ] && \
   [ "$LCD_snapshot" != "#" ] && \
   [ "$Cronfile" -eq "600" ]; then

    debug "Cronjob Validation - $Success"
    printf "\n" >> "${LOG}"

else

    debug "Cronjob Validation - $Failed"
    printf "\n" >> "${LOG}"

fi

#cat /home/pi/vendingserver/properties/vendingserver.properties

detect=/media/usb
Pendrive=$(lsblk | grep media | awk '{print $7}')

if [ "$Pendrive" == "$detect" ]; then

        debug "Pendrive - $Success"
        printf "\n" >> ${LOG}
else

        debug "Pendrive - $Failed"
        printf "\n" >> ${LOG}

fi

# Scenario - File exists and is a directory

if [ -d /media/usb/videos/ ];
then
    debug  "Videos Directory - $Success"
    printf "\n" >> ${LOG}
else
    debug "Videos Directory - $Failed"
    printf "\n" >> ${LOG}
fi

if [ -z "$(ls -A /media/usb/videos/)" ]; then

    debug  "Videos Folder Empty - $Failed"
    printf "\n" >> ${LOG}
else

    debug  "Videos Folder Empty - $Success"
    printf "\n" >> ${LOG}

fi

## refill videos 

# Scenario - Refill Videos directory exists and has files

if [ -d /media/usb/refillvideos/ ]; then

    debug "Refill Videos Directory - $Success"
    printf "\n" >> ${LOG}

else

    debug "Refill Videos Directory - $Failed"
    printf "\n" >> ${LOG}

fi


if [ -z "$(ls -A /media/usb/refillvideos/ 2>/dev/null)" ]; then

    debug "Refill Videos Folder Empty - $Failed"
    printf "\n" >> ${LOG}

else

    debug "Refill Videos Folder Empty - $Success"
    printf "\n" >> ${LOG}

fi

##video_device

if ls /dev/video* | grep -q "/dev/video0"; then
    debug  "Camera Detection - $Success"
    printf "\n" >> ${LOG}
else
    debug  "Camera Detection - $Failed"
    printf "\n" >> ${LOG}
fi

### Motion package status ###

   if [ -x "$(command -v motion)" ];
      then
    debug  "Motion package - Success"
    printf "\n" >> ${LOG}
else
    debug  "Motion package - Failed"
    printf "\n" >> ${LOG}

fi



#motion file check

#****new  code ***
# Execute the 'device id' command and store its output in a variable
device_output=$(ls -ltrh /dev/v4l/by-id/* | grep 'index0' | awk '{ print $9}')

    if sudo grep '^videodevice' /etc/motion/motion.conf | grep -qv "$device_output"; then
        echo "The device UUID not matching."
	sudo sed -i "/^videodevice/s|.*|videodevice $device_output|" /etc/motion/motion.conf
	echo "UUID updated"
	else
        echo "The device UUID  matching."
     fi


dev=`ls -ltrh /dev/v4l/by-id/* | grep 'index0' | awk '{ print $9}'`
mn=`sudo cat /etc/motion/motion.conf | grep 'videodevice /dev/' | awk  '{ print $2}'`

if [ "$dev" == "$mn" ];
then
    debug  "motiondeviceconf - Success"
    printf "\n" >> ${LOG}
else
    debug  "motiondeviceconf - Failed"
    printf "\n" >> ${LOG}
fi

#default motion status

sam=`sudo cat /etc/default/motion  | grep 'start_motion_daemon' | awk -F"=" '{print $2}'`

if [ "$sam" == "yes" ];
then
    debug  "Defaultmotion - Success"
    printf "\n" >> ${LOG}
else
    debug  "Defaultmotion - Failed"
    printf "\n" >> ${LOG}
fi

#########  NEW CODE ADDED...................

### False Video Format check ###
Format_check=`ls -lrt /media/usb/videos | grep -E 'jpg|mkv' | wc -l`
if [  "$Format_check" -lt "1" ];then
    debug  "False_VideoFormat - Success"
    printf "\n" >> ${LOG}
else
    debug  "False_VideoFormat - Failed"
    printf "\n" >> ${LOG}
fi

##Latest Video Availability
TO_DATE=$(date '+%Y-%m-%d')
YES_DATE=$(date --date=' 1 days ago' '+%Y-%m-%d')

V_path="/media/usb/videos"
Today_Availability=`ls -lrt ${V_path}/"$TO_DATE"*.avi`
Yesterday_Availability=`ls -lrt ${V_path}/*"$YES_DATE"*.avi`

Today_Availability_Count=`echo "$Today_Availability" | wc -l`
Yesterday_Availability_Count=`echo "$Yesterday_Availability" | wc -l`
M_time=`date +%R | cut -c '1-5'`
E_time=`date +%R | cut -c '1-5'`
M_Exec="07:00"
E_Exec="19:00"

if [ "$M_time" == "$M_Exec" ]; then
echo "Its morning 7:30...executing to check yesterday video"
	if [ "$Yesterday_Availability_Count" -ge "1" ]; then

        	debug "Latest Video - $Success"
	        printf "\n" >> ${LOG}
	else

        	debug "Latest Video - $Failed"
	        printf "\n" >> ${LOG}

	fi

   elif [ "$E_time" == "$E_Exec" ]; then
        echo "Its evening 19:30...executing to check today video"

        if [ "$Today_Availability_Count" -ge "1" ]; then

                debug "Latest Video - $Success"
                printf "\n" >> ${LOG}
        else

                debug "Latest Video - $Failed"
                printf "\n" >> ${LOG}
        fi
 else
	echo "time lapsed"
fi


### LCD Latest scripts  check ####
if [ -f /home/pi/lcd_snapshot.sh ] && [ -f /home/pi/lcd_snapshot_api.py ] && [ -f /home/pi/videoPull.py ] && [ -f /home/pi/videoRemove.py ]; then

	debug "LCD LatestScripts - $Success"
                printf "\n" >> ${LOG}  
else
	debug "LCD LatestScripts - $Failed"
                printf "\n" >> ${LOG}
fi

#### Video Device Validation & Auto correction #####

search_string1=$(cat /usr/bin/refill_transaction.sh | grep -oE 'ffmpeg')
search_string2=$(cat /home/pi/lcd_snapshot.sh | grep -o -m 1 'ffmpeg')

# Execute the 'device id' command and store its output in a variable
device_output=$(ls -ltrh /dev/v4l/by-id/* | grep 'index0' | awk '{ print $9}')
uudi1=$(cat /usr/bin/refill_transaction.sh | grep '/dev/' | awk -F" " '{print $11}')
uudi2=$(cat /home/pi/lcd_snapshot.sh | grep -m 1 '/dev/' | awk -F" " '{print $5}')

# Define the new ffmpeg command template
ffmpeg_command_template1="ffmpeg -f v4l2 -framerate 5 -video_size 1280x720 -input_format mjpeg -i {} -t 0:30:00.000 \$VIDEO_PATH/\$TIMESTAMP.avi >> \${LOG} 2>&1"
ffmpeg_command_template2='ffmpeg -f video4linux2 -i {} -vframes 1 -y /home/pi/lcd/"$mac$CURRENT_TIMESTAMP.jpeg"'

echo "search for refil scrpt"

if [ $search_string1 == "ffmpeg" ] && [ $device_output == $uudi1 ]; then
	echo "Required Strings available in script1"
else
	echo "The Required Strings not available in script1"
        # Replace any line containing 'ffmpeg' with the desired template
        sed -i "/$search_string1/c$ffmpeg_command_template1" /usr/bin/refill_transaction.sh
	sed -i "s|{}|$device_output|" /usr/bin/refill_transaction.sh
        echo "Replaced all lines containing '$search_string1' with the desired template."
fi

echo "searching for  lcd_snap script"

    # Execute the 'device id' command and store its output in a variable
    device_output=$(ls -ltrh /dev/v4l/by-id/* | grep 'index0' | awk '{ print $9}')

    # Check if the uuid output is present in the line containing 'ffmpeg'
    if grep  "$search_string2" /home/pi/lcd_snapshot.sh | grep -qv "$device_output"; then
        echo "The Required Strings not available in script2."

        # Replace any line containing 'ffmpeg' with the desired template
        sed -i "/$search_string2/c$ffmpeg_command_template2" /home/pi/lcd_snapshot.sh
        sed -i "s|{}|$device_output|" /home/pi/lcd_snapshot.sh
        echo "Replaced all lines containing '$search_string2' with the desired template."
	else
        echo "Required Strings available in script2."
     fi

# Device UUID Availability Check

if grep -q "$search_string1" /usr/bin/refill_transaction.sh  && grep -q "$device_output" /usr/bin/refill_transaction.sh ;then   echo "Success" >/home/pi/Desktop/rfile1 
 else   echo "Failed" >/home/pi/rfile1 
fi

if grep  "$search_string2" /home/pi/lcd_snapshot.sh | grep -qv "$device_output"; then echo "Failed" >/home/pi/Desktop/sfile2 
 else   echo "Success" >/home/pi/Desktop/sfile2
fi

file1=$(cat /home/pi/Desktop/rfile1)
file2=$(cat /home/pi/Desktop/sfile2)

if [ "$file1" == "Success" ] && [ "$file2" == "Success" ];then

        debug "Device UUID Availability - $Success"
        printf "\n" >> ${LOG}
else
        debug "Device UUID Availability - $Failed"
        printf "\n" >> ${LOG}

fi


### BLE SETUP  CHECK 

# Define the log directory
log_dir="/home/pi/bleserver-1.0.0/logs"

# Get the current date in the format YYYY-MM-DD
current_date=$(date +'%Y-%m-%d')

# Define log file paths
app_log="$log_dir/app.log"
beacon_log="$log_dir/beacon.log"

# Function to check if a process is running
is_process_running() {
    local process_name="$1"
    if pgrep -f "$process_name" > /dev/null; then
        return 0  # Process is running
    else
        return 1  # Process is not running
    fi
}

# Check if both log files contain entries for the current date
log_check=false

if grep -q "$current_date" "$app_log" && grep -q "$current_date" "$beacon_log"; then
    log_check=true
fi

# Check if both processes are running
server_process_check=false
beacon_process_check=false

	if is_process_running "/home/pi/bleserver-1.0.0/src/vs-ble-server.py"; then
    	server_process_check=true
	fi

	if is_process_running "/home/pi/bleserver-1.0.0/src/vs-ble-beacon.py"; then
	    beacon_process_check=true
	fi

# Check both log files and processes
    if [ "$log_check" = true ] && [ "$server_process_check" = true ] && [ "$beacon_process_check" = true ]; then

	debug "BLE Status - $Success"
        printf "\n" >> ${LOG}
        echo "Success: Both log files are synced with current date & both ble processes are running."
     else
	debug "BLE Status - $Failed"
        printf "\n" >> ${LOG}
	echo "Failed: One or both log files aren't synced with current date Or one or both ble processes not running."
    fi


##

curl -X POST -F file=@"/home/pi/Desktop/${Minion_ID}" https://iperf-bbinstant.bigbasket.com/csalerts
Forchk=`ls -lrt /home/pi | grep -E 'mp4' | awk -F " " '{print $9}' | awk -F "." '{print $2}'| wc -l`
#echo "$Forchk"
if [ "$Forchk" -gt 0 ];then
	sudo mv /home/pi/*.mp4 /media/usb/videos/
	debug "files present moved - $Success"
        printf "\n" >> ${LOG}
else
	debug "files not present - $Success"
        printf "\n" >> ${LOG}
fi

###camera focus issue

FILE="/home/pi/Desktop/test.jpeg"

rm -f /home/pi/Desktop/test.jpeg

ffmpeg -f video4linux2 -i /dev/video0 -vframes 1 -y "$FILE" >/dev/null 2>&1

if [ ! -f "$FILE" ]; then

    debug "Camera focus - FAILED (Image not generated)"
    printf "\n" >> ${LOG}

else
    SIZE=$(du -k "$FILE" | cut -f1)
    if [ "$SIZE" -ge 30 ]; then

        debug "Camera focus - SUCCESS"

    else

        debug "Camera focus - FAILED"

    fi

    printf "\n" >> ${LOG}

fi

cat $LOG
grep _CS /etc/salt/minion
