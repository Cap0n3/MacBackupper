#!/bin/bash  

#***ADMIN_MAIL Mail***

# ADMIN_MAIL="aguillin@protonmail.com"
# CC_MAIL=""

#WHAT FOLDER DO WANT TO BCKUP ? INSERT PATH HERE :
FOLDER_PATHS=('/Users/kalhal/Documents/Notes_Network'\ 
	''\ 
	''\
	'')

#WHERE DO YOU WANT TO BACKUP FOLDERS ? INSERT PATH HERE :
BACKUP_PATH='/Users/kalhal/Desktop/Testing'


#==================================================
#================== PROGRAM CODE ==================
#==================================================

#***USEFUL DATA***

HOME_DIR=$HOME
USERNAME=$USER
HOSTNAME=$(hostname)
EXEC_TIME=$(date "+%H:%M:%S")
EXEC_DATE=$(date "+%d/%m/%y")

# ***********************
# ****** FUNCTIONS ******
# ***********************

function log() {
	
	local logs_path="$HOME/Library/Logs"
	local log_folder_name="myMacBackupper"
	local full_path="$logs_path/$log_folder_name"
	local log_format="$EXEC_DATE $EXEC_TIME $HOSTNAME $USER:"
	local log_message=$1
	
	#Create log folder & file if doesn't exit or write 
	if [ -d $full_path ]
	then
		echo "$log_format $log_message" >> $full_path/myMacBackupper.log
	else
		mkdir $full_path
		echo "$log_format Created log folder at '$full_path'" >> $full_path/myMacBackupper.log
		#If there is a log message, log it !
		if ! [ -z $log_message ]
		then
			echo "$log_format $log_message" >> $full_path/myMacBackupper.log
		fi
	fi
}

function sendStatus() {
	#***EDIT HERE MESSAGE for E-Mail***	
	line1=$(echo "Hi there $USERNAME, your datas were successfully saved in $BACKUP_PATH1 !")
	line2=$(echo "- Backup of $FOLDER_PATH1 => Status code : $1")
	line3=$(echo "- Backup of $FOLDER_PATH2 => Status code : $2")
	bckupTime=$(echo "Execution time : $EXEC_DATE at $EXEC_TIME")
	errorMsg=$(echo "An error occured with $HOSTNAME ! Couldn't save data in $BACKUP_PATH1 ...")

	#***Send Mail***
	if [ $1 -eq 0 ] && [ $2 -eq 0 ]
	then
		echo -e "${line1}\n\n${line2}\n${line3}\n${backupTime}" | mail -s "Backup successfully Done" $ADMIN_MAIL -c $CC_MAIL
		echo $?
	else
		echo -e "${errorMsg}\n\n${line2}\n${line3}\n${backupTime}" | mail -s "Backup Failed !" $ADMIN_MAIL -c $CC_MAIL
		echo $?
	fi	
}


# ********************************************************
# ****** CHECK IF SOURCE & DESTINATION FOLDER EXIST ******
# ********************************************************

#Check source folder
for FOLDER_PATH in ${FOLDER_PATHS[@]}
do
	if ! [ -d $FOLDER_PATH ]
	then
		log "[ACCESS_DENIED] - '$FOLDER_PATH' source folder doesn't exist or is not accessible ! Script exited with status 2 !"
		exit 2		
fi
done

#Check destination folder
if ! [ -d $BACKUP_PATH ]
then
	log "[NOT_FOUND] - '$BACKUP_PATH' destination folder doesn't exist or is not accessible ! Script exited with status 2 !"
	exit 2	
fi

# ***************************
# ****** START BACKUP *******
# ***************************

for FOLDER_PATH in ${FOLDER_PATHS[@]}
do
	log "[INFO] - Starting backup of '$FOLDER_PATH' in '$BACKUP_PATH'"
	#Start backup
	bckup_cmd=$(rsync -arhv $FOLDER_PATH $BACKUP_PATH 2>&1)
	#If it's not a success
	if [ $? -ne 0 ]
	then
		log "[ERROR] - An error occured with '$FOLDER_PATH' => $bckup_cmd"
	else
		log "[SUCCESS] - '$FOLDER_PATH' successfully saved in '$BACKUP_PATH'"
	fi
done

exit
 
#***BACKUP COMMAND FOR PASSWORDS***

# rsync -arhv $FOLDER_PATH1 $BACKUP_PATH1
# status[0]=$?

# #***AND VOICE UP FOLDER***

# rsync -arhv $FOLDER_PATH2 $BACKUP_PATH1
# status[1]=$?

# sendStatus ${status[0]} ${status[1]}
