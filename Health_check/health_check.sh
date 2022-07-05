#!/bin/bash
NODE1_IP=192.168.218.135
NODE2_IP=192.168.218.136

IS_NODE1_DOWN=0
IS_NODE2_DOWN=0

node1_master=0
node2_master=0

FAIL=0

date=$(date)

kindalightblue=$(tput setaf 123)
echo ${kindalightblue}

ping -c 3 $NODE1_IP >/dev/null 2>&1
if [ $? -ne 0 ]; then
    IS_NODE1_DOWN=1
    echo "[ $date ]  NODE1 POSTGRES SERVER is DOWN"
else
    echo "[ $date ] NODE1 POSTGRES SERVER is UP"

    NODE1_SERVICE_STAT=$(ssh root@192.168.218.135 systemctl is-active postgresql@12-main)
    if [ "$NODE1_SERVICE_STAT" == "active" ]; then
        echo "[ $date ] NODE1 POSTGRES SERVICE is UP"
    else
        echo "[ $date ] NODE1 POSTGRES SERVICE is DOWN"
    fi
fi

ping -c 3 $NODE2_IP >/dev/null 2>&1
if [ $? -ne 0 ]; then
    IS_NODE2_DOWN=1
    echo "[ $date ] NODE2 POSTGRES SERVER is DOWN"
else
    echo "[ $date ] NODE2 POSTGRES SERVER is UP"

    NODE2_SERVICE_STAT=$(ssh root@192.168.218.136 systemctl is-active postgresql@12-main)
    if [ "$NODE2_SERVICE_STAT" == "active" ]; then
        echo "[ $date ] NODE2 POSTGRES SERVICE is UP"
    else
        echo "[ $date ] NODE2 POSTGRES SERVICE is DOWN"
    fi
fi

# NODE 1 IS DOWN BUT NODE 2 IS UP || NODE 1 IS UP BUT SERVICE IS DOWN
#
if ([ $IS_NODE1_DOWN == 1 ] && [ $IS_NODE2_DOWN == 0 ]) || ([ "$NODE1_SERVICE_STAT" != "active" ] && [ $IS_NODE2_DOWN == 0 ]); then
    echo "Do you want to promote NODE2 to MASTER? (y-n)"
    read promote_choice
    if [ $promote_choice == "y" ]; then
        promote_node2=$(ssh root@192.168.218.136 sudo pg_ctlcluster 12 main promote)
        if [ $? -eq 0 ]; then
            echo "[ $date ] NODE2 successfully promoted to MASTER"
            node2_master=1
        else
            echo "[ $date ] NODE2 failed to be promoted to MASTER"
        fi
    else
        echo "Bye"
    fi
fi

if [ $node2_master -eq 1 ] && [ $IS_NODE1_DOWN == 0 ]; then
    start_postgres=$(ssh root@192.168.218.135 sudo systemctl start postgresql@12-main)
    if [ $? -eq 1 ]; then
        echo "[ $date ] POSTGRES SERVICE START OK"
    else
        echo "[ $date ] POSTGRES SERVICE START FAIL"
    fi
    drop_replica_slot=$(psql -U postgres -h 192.168.218.135 -c "select pg_drop_replication_slot('slaveslot1');")
    if [ $? -eq 1 ]; then
        echo "[ $date ] POSTGRES DROP REPLICASLOT OK"
    else
        echo "[ $date ] POSTGRES DROP REPLICASLOT FAIL"
    fi
    remove=$(ssh root@192.168.218.135 sudo rm -rf /mnt/volume1)
    if [ $? -eq 0 ]; then
        echo "[ $date ] POSTGRES REMOVE FOLDER OK"
    else
        echo "[ $date ]  POSTGRES REMOVE FOLDER FAIL"
    fi
    create_folder=$(ssh root@192.168.218.135 mkdir -p /mnt/volume1/postgresql/12/main/ && ssh root@192.168.218.135 chown -R postgres:postgres /mnt/)
    if [ $? -eq 1 ]; then
        echo "[ $date ] POSTGRES CREATE FOLDER OK"
    else
        echo "[ $date ] POSTGRES CREATE FOLDER FAIL"
    fi
    backup=$(ssh postgres@192.168.218.135 sudo -u postgres pg_basebackup -h 192.168.218.136 -D /mnt/volume1/postgresql/12/main/ -U replicator -P -v -R -X stream -C -S slaveslot1)
    if [ $? -eq 1 ]; then
        echo "[ $date ] POSTGRES BACKUP SLAVESLOT1 OK"
    else
        echo "[ $date ] POSTGRES BACKUP SLAVESLOT1 FAIL"
    fi
fi

# NODE 2 IS DOWN BUT NODE 1 IS UP || NODE 2 IS UP BUT SERVICE IS DOWN
#
if ([ $IS_NODE2_DOWN == 1 ] && [ $IS_NODE1_DOWN == 0 ]) || ([ "$NODE2_SERVICE_STAT" != "active" ] && [ $IS_NODE1_DOWN == 0 ]); then
    echo "Do you want to promote NODE1 to MASTER? (y-n)"
    read promote_choice
    if [ $promote_choice == "y" ]; then
        promote_node1=$(ssh root@192.168.218.135 sudo pg_ctlcluster 12 main promote)
        if [ $? -eq 1 ]; then
            echo "[ $date ] NODE1 successfully promoted to MASTER"
            node1_master=1
        else
            echo "[ $date ] NODE1 failed to be promoted to MASTER"
        fi
    else
        echo "Bye"
    fi
fi

if [ $node1_master -eq 1 ] && [ $IS_NODE1_DOWN == 0 ]; then
    start_postgres=$(ssh root@192.168.218.136 sudo systemctl start postgresql@12-main)
    if [ $? -eq 1 ]; then
        echo "[ $date ] POSTGRES SERVICE START OK"
    else
        echo "[ $date ] POSTGRES SERVICE START FAIL"
    fi
    drop_replica_slot=$(psql -U postgres -d deneme -h 192.168.218.136 -c "select pg_drop_replication_slot('slaveslot1');")
    if [ $? -eq 1 ]; then
        echo "[ $date ] POSTGRES DROP REPLICASLOT OK"
    else
        echo "[ $date ] POSTGRES DROP REPLICASLOT FAIL"
    fi
    remove=$(ssh root@192.168.218.136 sudo rm -rf /mnt/volume1/postgresql/12/main/)
    if [ $? -eq 0 ]; then
        echo "[ $date ] POSTGRES REMOVE FOLDER OK"
    else
        echo "[ $date ]  POSTGRES REMOVE FOLDER FAIL"
    fi
    create_folder=$(ssh root@192.168.218.136 mkdir /mnt/volume1/postgresql/12/main/ && chown -R postgres:postgres /mnt/volume1/postgresql/12/*)
    if [ $? -eq 1 ]; then
        echo "[ $date ] POSTGRES CREATE FOLDER OK"
    else
        echo "[ $date ] POSTGRES CREATE FOLDER FAIL"
    fi
    backup=$(ssh postgres@192.168.218.136 sudo -u postgres pg_basebackup -h 192.168.218.135 -D /mnt/volume1/postgresql/12/main/ -U replicator -P -v -R -X stream -C -S slaveslot1)
    if [ $? -eq 1 ]; then
        echo "[ $date ] POSTGRES BACKUP SLAVESLOT1 OK"
    else
        echo "[ $date ] POSTGRES BACKUP SLAVESLOT1 FAIL"
    fi
fi
