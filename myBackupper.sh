#!/bin/bash  

source myBackupper.config
source utils/colors.sh

#==================================================#
#================== MY BACKUPPER ==================#
#==================================================#

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXEC_TIME=$(date "+%H:%M:%S")
EXEC_DATE=$(date "+%d/%m/%y")

#\\=============================================================#
#\\ FUNCTIONS 
#\\=============================================================#

#############################################
# NAME : getOS()
# Get OS name (used by log() to decide 
# how to log messages depending if MAC/LINUX)
# Globals:
#   OSTYPE
# Arguments:
#   None
# Output:
# 	Assigned to a var in log()
#############################################

function getOS() {

	local os_name

	case "$OSTYPE" in
		solaris*)
			os_name="solaris"
			echo $os_name
		;;
		darwin*)
			os_name="macOs"
			echo $os_name
		;;
		linux*)
			os_name="linux"
			echo $os_name
		;;
		bsd*)
			os_name="bsd"
			echo $os_name
		;;
		msys*)
			os_name="windows"
			echo $os_name
		;;
	esac
}

###############################################
# NAME : writeLog()
# Custom logging system for MAC & standard
# Linux 'logger' cmd for Linux.
# Globals:
#   EXEC_DATE 
#	EXEC_TIME 
#	HOSTNAME 
#	USER
# Arguments:
#   Log Message, log severity level
# Output:
# 	to Console utility (mac) ~/Library/Logs/<app_name>, 
# 	to logger command for linux
###############################################

function writeLog() {
	
	local log_message=$1
	local severity=$2
	#Must separate declaration from assignation for local var commands
	local os_type
	os_type=$(getOS)

	if [ $os_type == "macOs" ]
	then
		local logs_path="$HOME/Library/Logs"
		local log_folder_name="myBackupper"
		local full_path="$logs_path/$log_folder_name"
		local log_format="[*] $EXEC_DATE $EXEC_TIME $HOSTNAME $USER:"
		
		#Create log folder & file if doesn't exit or write 
		if [ -d $full_path ]
		then
			echo -e "$log_format $log_message\n" >> $full_path/myMacBackupper.log
		else
			mkdir $full_path
			echo "$log_format Created log folder at '$full_path'" >> $full_path/myMacBackupper.log
			#Create log folder and write log message
			if ! [ -z $log_message ]
			then
				echo -e "$log_format $log_message\n" >> $full_path/myMacBackupper.log
			fi
		fi
	elif [ $os_type == "linux" ]
	then
		logger -p local7.$severity -t myBackupper "$log_message"
	else
		echo -e "\nThis script is not compatible with your system type ('$os_type') ! Works only on MacOS and Linux.\n"
		exit 2
	fi
}

###############################################
# NAME : pingAddress
# This function pings n times to see 
# if ressource is online.
# Globals:
#   NAS_ADDRESS
# Arguments:
#   n_times (ping n times)
# Output:
#	to stdout
# 	to Console utility (mac), to logger (linux)
###############################################

function pingAddress() {
	
	local n_times=$1
	
	for ((i = 0 ; i < $n_times ; i++))
	do
		#Must separate declaration from assignation for local var commands
		local ping_cmd
		ping_cmd=$(ping -q -c 1 -W 1000 $NAS_ADDRESS 2>&1)

		# HERE !!! May be awk '{print $7}' instead for MacOS ... to check !!!
		local packet_loss
		packet_loss=$(echo "$ping_cmd" | grep % | awk '{print $6}')
		
		# HERE !!! May be 0.0% and 100.0% instead for MacOS ... to check !!!
		if [ $packet_loss == "0%" ]
		then
			writeLog "[HOST_UP] - '$NAS_ADDRESS' is up !" "info"
			echo -e "\n[HOST_UP] - '$NAS_ADDRESS' is up !"
			break
		elif [ $packet_loss == "100%" ]
		then
			writeLog "[HOST_DOWN] - '$NAS_ADDRESS' seems down ... try again !" "warn"
			echo -e "\n[HOST_DOWN] - '$NAS_ADDRESS' seems down ... try again !"
		else
			writeLog "[ERROR] - $ping_cmd" "err"
			echo -e "\n[ERROR] - $ping_cmd"
			exit 1
		fi
	done
}

#############################################
# NAME : sendStatus()
# TO DO !!!
# Send mail if success/failure if user wants
# Globals:
#   USERNAME
#	HOSTNAME
#	EXEC_DATE
#	EXEC_TIME
#	DEST_PATH
# Arguments:
#   Status message
# Output:
# 	To mail
#############################################

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

#\\=============================================================#
#\\ VERIFICATIONS (check if source/destination exist & accessible)
#\\=============================================================#

#Check of source folders exists or are accessible (exit & output error if necessary)
for FOLDER_PATH in ${FOLDER_PATHS[@]}
do
	if ! [ -d $FOLDER_PATH ]
	then
		writeLog "[ACCESS_DENIED] - '$FOLDER_PATH' source folder doesn't exist or is not accessible ! Script exited with status 2 !" "err"
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
	writeLog "[NOT_FOUND] - '$DEST_PATH' destination folder doesn't exist or is not accessible ! Script exited with status 2 !" "err"
	echo -e "[NOT_FOUND] - '$DEST_PATH' destination folder doesn't exist or is not accessible ! Script exited with status 2 !"
	exit 2	
fi

#\\=============================================================#
#\\ START ACTUAL BACKUP
#\\=============================================================#

for FOLDER_PATH in ${FOLDER_PATHS[@]}
do
	writeLog "[INFO] - Starting backup of '$FOLDER_PATH' in '$DEST_PATH'" "info"
	echo -e "${CYAN}[INFO]${RESET} Starting backup of '$FOLDER_PATH' in '$DEST_PATH'"
	# Start backup
	rsync -arh $FOLDER_PATH $DEST_PATH --info=progress2 | tee /dev/tty
	# Get Exit code of command
	exit_code=$?

	#If it's not a success
	if [ "$exit_code" -ne 0 ]
	then
		#Something went wrong - Grep error line ==> TO RE-THINK !!!
		# errMsg=$(echo "$bckup_cmd" | grep rsync:)
		
		#Create empty array to store corrupted file links (for report)
		corr_files=()
		#Log exact rsync error code for further investigation
		case "$exit_code" in
			1)
				writeLog "[RSYNC ERROR] - Syntax or usage error. (exit code 1)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} Syntax or usage error. (exit code 1)\n"
				exit 1
			;;
			2)
				writeLog "[RSYNC ERROR] - Protocol incompatibility. (exit code 2)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} Protocol incompatibility. (exit code 2)"
				exit 1
			;;
			3)
				writeLog "[RSYNC ERROR] - Errors selecting input/output files, dirs. (exit code 3)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} Errors selecting input/output files, dirs. (exit code 3)"
				exit 1
			;;
			4)
				writeLog "[RSYNC ERROR] - Requested action not supported: an attempt was made to manipulate 64-bit files on a platform that cannot support them; or an option was specified that is supported by the client and not by the server. (exit code 4)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} Requested action not supported: an attempt was made to manipulate 64-bit files on a platform that cannot support them; or an option was specified that is supported by the client and not by the server. (exit code 4)"
				exit 1
			;;
			5)
				writeLog "[RSYNC ERROR] - Error starting client-server protocol. (exit code 5)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} Error starting client-server protocol. (exit code 5)"
				exit 1
			;;
			6)
				writeLog "[RSYNC ERROR] - Daemon unable to append to writeLog-file. (exit code 6)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} Daemon unable to append to writeLog-file. (exit code 6)"
				#NO EXIT
			;;
			10)
				writeLog "[RSYNC ERROR] - Error in socket I/O. (exit code 10)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} Error in socket I/O. (exit code 10)"
				exit 1
			;;
			11)
				writeLog "[RSYNC ERROR] - Error in file I/O. (exit code 11)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} Error in file I/O. (exit code 11)"
				exit 1
			;;
			12)
				writeLog "[RSYNC ERROR] - Error in rsync protocol data stream. (exit code 12)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} Error in rsync protocol data stream. (exit code 12)"
				exit 1
			;;
			13)
				writeLog "[RSYNC ERROR] - Errors with program diagnostics. (exit code 13)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} Errors with program diagnostics. (exit code 13)"
				#NO EXIT
			;;
			14)
				writeLog "[RSYNC ERROR] - Error in IPC code. (exit code 14)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} Error in IPC code. (exit code 14)"
				exit 1
			;;
			20)
				writeLog "[RSYNC ERROR] - Received SIGUSR1 or SIGINT. (exit code 20)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} Received SIGUSR1 or SIGINT. (exit code 20)"
				#NO EXIT
			;;
			21)
				writeLog "[RSYNC ERROR] - Some error returned by waitpid(). (exit code 21)" "err"
				echo -n "${RED}[RSYNC ERROR]${RESET} Some error returned by waitpid(). (exit code 21)"
				#NO EXIT
			;;
			22)
				writeLog "[RSYNC ERROR] - Error allocating core memory buffers. (exit code 22)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} Error allocating core memory buffers. (exit code 22)"
				exit 1
			;;
			23)
				writeLog "[RSYNC ERROR] - Partial transfer due to error. (exit code 23) =>\n[ERROR MSG] - $errMsg" "err"
				#Store corrupted file paths for listing
				corr_file_path=$(echo "$errMsg" | awk -F '"|"' '{print $2}')
				corr_files+=($corr_file_path)
				echo -e "${RED}[RSYNC ERROR]${RESET} Partial transfer due to error. (exit code 23). See logs for more infos."
				#NO EXIT
			;;
			24)
				writeLog "[RSYNC ERROR] - Partial transfer due to vanished source files. (exit code 24)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} Partial transfer due to vanished source files. (exit code 24)"
				#NO EXIT
			;;
			25)
				writeLog "[RSYNC ERROR] - The --max-delete limit stopped deletions. (exit code 25)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} The --max-delete limit stopped deletions. (exit code 25)"
				#NO EXIT
			;;
			30)
				writeLog "[RSYNC ERROR] - Timeout in data send/receive. (exit code 30)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} Timeout in data send/receive. (exit code 30)"
				exit 1
			;;
			35)
				writeLog "[RSYNC ERROR] - Timeout waiting for daemon connection. (exit code 35)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} Timeout waiting for daemon connection. (exit code 35)"
				exit 1
			;;
			127)
				writeLog "[RSYNC ERROR] - Rsync is not installed on your system ! Please install it before running the script (exit code 127)" "err"
				echo -e "${RED}[RSYNC ERROR]${RESET} Rsync is not installed on your system ! Please install it before running the script (exit code 127)"
				exit 1
			;;
		esac

		#Only partial success because some non 'fatal' errors were encoutered.
		writeLog "[PARTIAL BACKUP] - '$FOLDER_PATH' partially saved in '$DEST_PATH'. Some errors were encountered." "info"
		echo -e "${YELLOW}[PARTIAL BACKUP]${RESET} - '$FOLDER_PATH' partially saved in '$DEST_PATH'. Some errors were encountered, see log or report for more infos."
	
	else
		writeLog "[SUCCESS] - '$FOLDER_PATH' successfully saved in '$DEST_PATH'. No error was encountered !" "info"
		echo -e "${GREEN}[SUCCESS]${RESET} '$FOLDER_PATH' successfully saved in '$DEST_PATH'. No error was encountered !"
	fi
done

#\\=============================================================#
#\\ BACKUP REPORT FOR USER
#\\=============================================================#

echo -e "#================================================================#" > "$DIR/backup_report.txt"
echo -e "#======================== BACKUP REPORT =========================#" >> "$DIR/backup_report.txt"
echo -e "#================================================================#\n\n" >> "$DIR/backup_report.txt"
echo -e "EXCUTION DATE & TIME :" >> "$DIR/backup_report.txt"
echo -e "--------------------\n" >> "$DIR/backup_report.txt"
echo -e "- $EXEC_DATE at $EXEC_TIME" >> "$DIR/backup_report.txt"
echo -e "\nSOURCE FOLDER(S) :" >> "$DIR/backup_report.txt"
echo -e "----------------\n" >> "$DIR/backup_report.txt"
for src_folders in "${FOLDER_PATHS[@]}";do echo -e "- $src_folders" >> "$DIR/backup_report.txt";done
echo -e "\nDESTINATION FOLDER :" >> "$DIR/backup_report.txt"
echo -e "------------------\n" >> "$DIR/backup_report.txt"
echo -e "- $DEST_PATH" >> "$DIR/backup_report.txt"
echo -e "\nERRORS :" >> "$DIR/backup_report.txt"
echo -e "------\n" >> "$DIR/backup_report.txt"
echo -e "[!] Total file errors : ${#corr_files[@]}" >> "$DIR/backup_report.txt"
echo -e "[!] Problematic files :\n" >> "$DIR/backup_report.txt"
for corr_file_path in "${corr_files[@]}"
do
    echo -e "- $corr_file_path" >> "$DIR/backup_report.txt"
done