#!/bin/bash

export $(grep -v '^#' .env | xargs)

echo -e "\nNode IP's :"
echo $NODE1_IP
echo $NODE2_IP

# HEALTH CHECK STARTS
echo -e "\nHealth Check Starting...\n"

. /home/turkai/Desktop/Postgres/Health_check/health_check.sh

health_check

if [ "$NODE1_IP" = "$master_cluster" ] && ([ $IS_NODE1_DOWN -eq 1 ] || [ "$NODE1_SERVICE_STAT" != "active" ]); then
    echo "NODE1 IS MASTER AND DOWN"
    echo "Commencing Promote of NODE2..."

    export master_cluster
    export replica_cluster
    # /home/turkai/Desktop/Postgres/Health_check/promote_master.sh
elif
    [ "$NODE2_IP" = "$master_cluster" ] && ([ $IS_NODE2_DOWN -eq 1 ] || [ "$NODE2_SERVICE_STAT" != "active" ])
then
    echo "NODE2 IS MASTER AND DOWN"
    echo "Commencing Promote of NODE1..."

    export master_cluster
    export replica_cluster
    # /home/turkai/Desktop/Postgres/Health_check/promote_master.sh
fi
