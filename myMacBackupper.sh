#!/bin/bash  

source myBackupper.config

#==================================================#
#================== MY BACKUPPER ==================#
#==================================================#

#*************************#
#****** USEFUL DATA ******#
#*************************#

EXEC_TIME=$(date "+%H:%M:%S")
EXEC_DATE=$(date "+%d/%m/%y")

# ***********************#
# ****** FUNCTIONS ******#
# ***********************#

function getOS() {
	case "$OSTYPE" in
		solaris*)
			local os_name="solaris"
			echo $os_name
		;;
		darwin*)
			local os_name="macOs"
			echo $os_name
		;;
		linux*)
			local os_name="linux"
			echo $os_name
		;;
		bsd*)
			local os_name="bsd"
			echo $os_name
		;;
		msys*)
			local os_name="windows"
			echo $os_name
		;;
	esac

}

function log() {
	#Custom logging system for MAC & Linux
	#On mac check console utility at ~/Library/Logs/<app_name>
	local log_message=$1
	local severity=$2
	local os_type=$(getOS)

	if [ $os_type == "macOs" ]
	then
		local logs_path="$HOME/Library/Logs"
		local log_folder_name="myMacBackupper"
		local full_path="$logs_path/$log_folder_name"
		local log_format="$EXEC_DATE $EXEC_TIME $HOSTNAME $USER:"
		
		#Create log folder & file if doesn't exit or write 
		if [ -d $full_path ]
		then
			echo -e "$log_format $log_message" >> $full_path/myMacBackupper.log
		else
			mkdir $full_path
			echo "$log_format Created log folder at '$full_path'" >> $full_path/myMacBackupper.log
			#Create log folder and write log message
			if ! [ -z $log_message ]
			then
				echo -e "$log_format $log_message" >> $full_path/myMacBackupper.log
			fi
		fi
	elif [ $os_type == "linux" ]
	then
		logger -p local7.$severity -t myBackupper $log_message
	else
		echo -e "\nThis script is not compatible with your system type ('$os_type') ! Works only on MacOS and Linux.\n"
		exit 2
	fi
}

function pingAddress() {
	#This function pings n times to see if ressource is online

	n_times=$1
	
	for ((i = 0 ; i < $n_times ; i++))
	do
		PING_CMD=$(ping -q -c 1 -W 1000 $NAS_ADDRESS 2>&1)
		PACKET_LOSS=$(echo "$PING_CMD" | grep % | awk '{print $7}')

		if [ $PACKET_LOSS == "0.0%" ]
		then
			log "[HOST_UP] - '$NAS_ADDRESS' is up !" "info"
			echo -e "[HOST_UP] - '$NAS_ADDRESS' is up !"
			break
		elif [ $PACKET_LOSS == "100.0%" ]
		then
			log "[HOST_DOWN] - '$NAS_ADDRESS' seems down ... try again !" "warn"
			echo -e "[HOST_DOWN] - '$NAS_ADDRESS' seems down ... try again !"
		else
			log "[ERROR] - $PING_CMD" "err"
			echo -e "[ERROR] - $PING_CMD"
			exit 1
		fi
	done
}

function sendStatus() {
	#***EDIT HERE MESSAGE for E-Mail***	
	line1=$(echo "Hi there $USERNAME, your datas were successfully saved in $DEST_PATH !")
	line2=$(echo "- Backup of $FOLDER_PATH => Status code : $1")
	bckupTime=$(echo "Execution time : $EXEC_DATE at $EXEC_TIME")
	errorMsg=$(echo "An error occured with $HOSTNAME ! Couldn't save data in $DEST_PATH ...")

	#***Send Mail***
	if [ $1 -eq 0 ] && [ $2 -eq 0 ]
	then
		echo -e "${line1}\n\n${line2}\n${backupTime}" | mail -s "Backup successfully Done" $ADMIN_MAIL -c $CC_MAIL
		echo $?
	else
		echo -e "${errorMsg}\n\n${line2}\n${backupTime}" | mail -s "Backup Failed !" $ADMIN_MAIL -c $CC_MAIL
		echo $?
	fi	
}

#********************************************************#
#****** CHECK IF SOURCE & DESTINATION FOLDER EXIST ******#
#********************************************************#

#Check of source folders exists or are accessible (exit & output error if necessary)
for FOLDER_PATH in ${FOLDER_PATHS[@]}
do
	if ! [ -d $FOLDER_PATH ]
	then
		log "[ACCESS_DENIED] - '$FOLDER_PATH' source folder doesn't exist or is not accessible ! Script exited with status 2 !" "err"
		echo -e "[ACCESS_DENIED] - '$FOLDER_PATH' source folder doesn't exist or is not accessible ! Script exited with status 2 !"
		exit 2		
fi
done

#If NAS option is active, check if ressource is available online (10 times and then give up)
if [ $NAS_BACKUP == true ]
then
	pingAddress 10
fi

#Check if destination folder exists or is accessible (output error if necessary)
if ! [ -d $DEST_PATH ]
then
	log "[NOT_FOUND] - '$DEST_PATH' destination folder doesn't exist or is not accessible ! Script exited with status 2 !" "err"
	echo -e "[NOT_FOUND] - '$DEST_PATH' destination folder doesn't exist or is not accessible ! Script exited with status 2 !"
	exit 2	
fi

#***************************#
#****** START BACKUP *******#
#***************************#

for FOLDER_PATH in ${FOLDER_PATHS[@]}
do
	log "[INFO] - Starting backup of '$FOLDER_PATH' in '$DEST_PATH'"
	#Start backup
	bckup_cmd=$(rsync -arhv $FOLDER_PATH $DEST_PATH 2>&1)
	#If it's not a success
	if [ $? -ne 0 ]
	then
		log "[ERROR] - An error occured with '$FOLDER_PATH' => $bckup_cmd" "err"
		echo -e "An error occured with '$FOLDER_PATH' => $bckup_cmd"
		exit 127
	else
		log "[SUCCESS] - '$FOLDER_PATH' successfully saved in '$DEST_PATH'" "info"
		log "\n\n======== BCKUP_OUTPUT_INFO =======\n==================================\nSRC => $FOLDER_PATH\n\n$bckup_cmd\n==================================\n" "info"
		echo -e "\n\n======== BCKUP_OUTPUT_INFO =======\n==================================\nSRC =>$FOLDER_PATH\n\n$bckup_cmd\n==================================\n"
	fi
done

#***BACKUP COMMAND FOR PASSWORDS***

# rsync -arhv $FOLDER_PATH1 $DEST_PATH1
# status[0]=$?

# #***AND VOICE UP FOLDER***

# rsync -arhv $FOLDER_PATH2 $DEST_PATH1
# status[1]=$?

# sendStatus ${status[0]} ${status[1]}
