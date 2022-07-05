#!/bin/bash

FAIL=0

job_1=`test ! -f turkai@192.168.1.250:/volume1/backup/burak-postgres/%f && rsync -a /var/lib/postgresql/pg_log_archive turkai@192.168.1.250:/volume1/backup/burak-postgres/`

$job_1 & pid_1=$!

date=$(date)

echo "$date Spawned replication processes $pid_1"

wait $pid_1 || let "FAIL+=1"

if [ "$FAIL" == "0" ]; then
    job_2=`rm -rf /var/lib/postgresql/pg_log_archive/*`
    $job_2 & pid_2=$!
    wait $pid_2 || let "FAIL+=1"
        if [ "$FAIL" == "1" ]; then
                echo "$date Cleaning the pg_log_archive failed."
        else
                echo "$date Cleaning the pg_log_archive success."
        fi
fi

if [ "$FAIL" == "0" ]; then
    echo "$date Replication success $1"
else
    echo "$date Replication failed $1"
fi