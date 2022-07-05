#!/bin/bash

FAIL=0

job_1=`rsync -a turkai@192.168.1.250:/volume1/backup/burak-postgres/db_file_backup /var/lib/postgresql/`

$job_1 & pid_1=$!
date=$(date)

echo "$date Spawned backup restoration processes $pid_1"

wait $pid_1 || let "FAIL+=1"

if [ "$FAIL" == "0" ]; then
    echo "$date Restoration success $1"
else
    echo "$date Restoration failed $1"
fi

echo "Do you want to extract the restored files? (y-n)"
read tar_choice

if [ $tar_choice == "y" ]; then
    
    job_3=`mkdir /mnt/volume1/postgresql/12/main/ && rsync -a /var/lib/postgresql/db_file_backup/ -C /mnt/volume1/postgresql/12/main/`
    job_4=`chown -R postgres:postgres /mnt/volume1/postgresql/12/*`    
    job_5=`chown -R postgres:postgres /var/lib/postgresql/*`


    $job_3 & pid3=$!
    $job_4 & pid4=$!
    $job_5 & pid5=$!


    wait $pid_3 || let "FAIL+=1"
    wait $pid_4 || let "FAIL+=1"
    wait $pid_5 || let "FAIL+=1"
    
    if [ "$FAIL" == "0" ]; then
    echo "Extraction success"
    else
    echo "Extraction failed"
    fi

else
    echo "Bye now."
fi
