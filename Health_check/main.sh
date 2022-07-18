#!/bin/bash

export $(grep -v '^#' .env | xargs)

echo -e "\nNode IP's :"
echo $NODE1_IP
echo $NODE2_IP

echo -e "\nHealth Check Starting...\n"
/home/turkai/Desktop/Postgres/Health_check/health_check.sh
