#!/bin/bash

while true; do
    export $(grep -v '^#' .env | xargs)

    color=$(tput setaf 115)
    echo ${color}

    date=$(date)

    echo -e "\n[ $date ] NODE IP'S :"
    echo "[ $date ] NODE 1 : $NODE1_IP"
    echo "[ $date ] NODE 2 : $NODE2_IP"

    # HEALTH CHECK STARTS
    echo -e "\n[ $date ] HEALTH CHECK STARTING..."

    . /home/turkai/Desktop/Postgres/Health_check/health_check.sh

    health_check

    # IF HEALTH CHECK RETURNS PROMOTE == 1 , PROMOTE MASTER
    if [[ $promote -eq 1 ]]; then
        . /home/turkai/Desktop/Postgres/Health_check/promote_master.sh

        promote_master
    elif [[ $IS_NODE1_DOWN -eq 1 ]] && [[ $IS_NODE2_DOWN -eq 1 ]]; then
        echo -e "\n[ $date ] BOTH SERVERS ARE DOWN!!!"
    else
        echo -e "\n[ $date ] MASTER IS UP AND RUNNING"
    fi
done
