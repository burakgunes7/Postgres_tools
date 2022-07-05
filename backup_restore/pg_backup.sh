#!/bin/bash

FAIL=0


job_1=`test ! -f turkai@192.168.1.250:/volume1/backup/burak-postgres/db_file_backup && sudo -u postgres pg_basebackup -Fp -D /var/lib/postgresql/db_file_backup`
job_2=`rsync -a /var/lib/postgresql/db_file_backup/ turkai@192.168.1.250:/volume1/backup/burak-postgres/db_file_backup`


$job_1 & pid_1=$!
$job_2 & pid_2=$!

date=$(date)

echo "$date Spawned processes $pid_1 $pid_2"

wait $pid_1 || let "FAIL+=1"
wait $pid_2 || let "FAIL+=1"

if [ "$FAIL" == "0" ]; then
    echo "$date Backup success $1"
else
    echo "$date Backup failed $1"
fi