#!/bin/bash

FAIL=0

job_1=`rsync -a turkai@192.168.1.250:/volume1/backup/burak-postgres/pg_log_archive /var/lib/postgresql/`

$job_1 & pid_1=$!
date=$(date)

echo "$date Spawned restoration processes $pid_1"

wait $pid_1 || let "FAIL+=1"

if [ "$FAIL" == "0" ]; then
    echo "$date Restoration success $1"
else
    echo "$date Restoration failed $1"
fi