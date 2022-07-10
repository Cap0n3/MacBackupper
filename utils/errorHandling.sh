#!/bin/bash

#####################################################
# NAME : error()
# Handle rsync errors based on command exit code
# Globals:
#   None
# Arguments:
#   Comand exit status, source path, destination path
# Output:
# 	Standard output and logs
######################################################
function error {
    # Get exit status
    local exit_code=$1
    local source_path=$2
    local dest_path=$3
    
    # Get exact error & echo + log it
    if [ "$exit_code" -ne 0 ]
	then
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
    fi
}

#####################################################
# NAME : success()
# Handle rsync command success
# Globals:
#   None
# Arguments:
#   Comand exit status, source path, destination path
# Output:
# 	Standard output and logs
######################################################
function success {
    local exit_code=$1
    local source_path=$2
    local dest_path=$3

    if [ "$exit_code" -eq 0 ]
    then
        writeLog "[SUCCESS] - '$source_path' successfully saved in '$dest_path'. No error was encountered !" "info"
		echo -e "${GREEN}[SUCCESS]${RESET} '$source_path' successfully saved in '$dest_path'. No error was encountered !"
    fi
}