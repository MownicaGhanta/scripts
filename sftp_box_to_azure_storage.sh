#!/bin/bash

# TODO: Update Azure storage path, remove ls line and uncomment rm line, uncomment startearly and cps move_and_sendmail lines 

# Unmount and remount storage container
fusermount -uz /home/saiirccecids
/home/configs/fuse_mount.sh

echo "Transferring files from cecids-sftp to IIRA Azure storage account"
echo "Check the log in /home/iirc-admin/logs/sftp_to_azure_storage.log"
log_file_path='/home/iirc-admin/logs/sftp_to_azure_storage.log'
echo "Checking for files" > $log_file_path

# If files in sftp box: 1) cp to storage account 2) remove from sftp box 3) send email
move_and_sendmail () {
		# 1: sftp box dir name
		# 2: Azure storage name
		# 3: log_file_path
		
		# Get the date from the next Sunday
		d=now
		d=${d##*-}-${d%-*}
		LOAD_DT=$(date -d "$d -$(date -d $d +%u) days + 7 days" +"%Y_%m_%d")
		
		echo "Checking $1" >> $3
		if ls -1qA /home/$1/Inbound/ | grep -q .
		then  
			        # Rename files
				if [[ "$2" == "easterseals" ]]; then
					declare -a tables=("Attendance" "Family" "Immunization" "Personnel" "Students" "Agency")
				elif [[ "$2" == "startearly" ]]; then
					declare -a tables=("ClassAttendance" "IndividualAttendance" "ChildInformation" "StaffInformation" "AgencyInformation")
				elif [[ "$2" == "CPS" ]]; then
					declare -a tables=("proto_applic_cecids" "proto_attend_cecids" "proto_programs_cecids" "proto_enrolls_cecids" "proto_students_cecids" "proto_teacher_cecids" "proto_roster_cecids" "proto_classroom_cecids")
				fi

				for table in "${tables[@]}"
				do
					mv /home/$1/Inbound/*${table}*.csv /home/$1/Inbound/${table}_${LOAD_DT}.csv
				done

				# Copy to storage
				cp /home/$1/Inbound/* /home/saiirccecids/Data/$2/Archive/
				echo "Copied from /home/$1/Inbound/ to /home/saiirccecids/Data/$2/Archive/" >> $3
				# Email notification
				python3 /home/iirc-admin/scripts/sendmail.py $1

				# Remove sftp files if exist in Archive
				echo "Remove files:" >> $3
				for table in "${tables[@]}"
				do
					[ ! -e /home/saiirccecids/Data/$2/Archive/${table}_${LOAD_DT}.csv ] || rm /home/$1/Inbound/${table}_${LOAD_DT}.csv
				done
		else  echo "$1 is empty" >> $3
		fi
		
}

move_and_sendmail sftp_easter easterseals $log_file_path
move_and_sendmail sftp_start startearly $log_file_path
move_and_sendmail sftp_cps CPS $log_file_path

echo "Complete" >> $log_file_path
