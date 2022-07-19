#!/bin/bash
health_check() {

    export $(grep -v '^#' .env | xargs)

    master_cluster=null
    replica_cluster=null

    IS_NODE1_DOWN=0
    IS_NODE2_DOWN=0

    FAIL=0

    PROMOTE=0

    date=$(date)

    color=$(tput setaf 123)
    echo ${color}

    # PING NODE_1 TO CHECK IF SERVER IS UP
    ping -c 3 $NODE1_IP >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        IS_NODE1_DOWN=1
        echo "[ $date ]  NODE1 POSTGRES SERVER IS DOWN"
    else
        echo "[ $date ] NODE1 POSTGRES SERVER IS UP"

        #   CHECK THE POSTGRES SERVER IF THE SERVER IS UP
        NODE1_SERVICE_STAT=$(ssh root@$NODE1_IP systemctl is-active postgresql@12-main)
        if [ "$NODE1_SERVICE_STAT" == "active" ]; then
            echo "[ $date ] NODE1 POSTGRES SERVICE is UP"
        else
            echo "[ $date ] NODE1 POSTGRES SERVICE is DOWN"
        fi
    fi

    # CHECK IF THE SERVER IS MASTER NODE OR REPLICA NODE IF NODE_1 IS UP
    if [ $IS_NODE1_DOWN -ne 1 ]; then
        find=$(ssh root@$NODE1_IP find /mnt/volume1/postgresql/12/main/ -name standby.signal)
        if [ "$find" != "/mnt/volume1/postgresql/12/main/standby.signal" ]; then
            echo -e "\n[ $date ] NODE1 IS MASTER CLUSTER\n"
            master_cluster=$NODE1_IP
        else
            echo -e "\n[ $date ] NODE1 IS REPLICA CLUSTER\n"
            replica_cluster=$NODE1_IP
        fi
    fi

    # PING NODE_2 TO CHECK IF SERVER IS UP
    ping -c 3 $NODE2_IP >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        IS_NODE2_DOWN=1
        echo "[ $date ] NODE2 POSTGRES SERVER IS DOWN"
    else
        echo "[ $date ] NODE2 POSTGRES SERVER IS UP"

        #   CHECK THE POSTGRES SERVER IF THE SERVER IS UP
        NODE2_SERVICE_STAT=$(ssh root@$NODE2_IP systemctl is-active postgresql@12-main)
        if [ "$NODE2_SERVICE_STAT" == "active" ]; then
            echo "[ $date ] NODE2 POSTGRES SERVICE IS UP"
        else
            echo "[ $date ] NODE2 POSTGRES SERVICE IS DOWN"
        fi
    fi

    # CHECK IF THE SERVER IS MASTER NODE OR REPLICA NODE IF NODE_2 IS UP
    if [ $IS_NODE2_DOWN -ne 1 ]; then

        find=$(ssh root@$NODE2_IP find /mnt/volume1/postgresql/12/main/ -name standby.signal)
        if [ "$find" != "/mnt/volume1/postgresql/12/main/standby.signal" ]; then
            echo -e "\n[ $date ] NODE2 is MASTER CLUSTER "
            master_cluster=$NODE2_IP
        else
            echo -e "\n[ $date ] NODE2 is REPLICA CLUSTER"
            replica_cluster=$NODE2_IP
        fi
    fi

    if [ "$NODE1_IP" = "$master_cluster" ] && ([ $IS_NODE1_DOWN -eq 1 ] || [ "$NODE1_SERVICE_STAT" != "active" ]); then
        echo -e "\n[ $date ] NODE1 IS MASTER AND DOWN"
        echo "[ $date ] Commencing Promote of NODE2..."
        promote+=1
        export master_cluster
        export IS_NODE1_DOWN
        export NODE1_SERVICE_STAT
        export replica_cluster
        export IS_NODE2_DOWN
        export NODE2_SERVICE_STAT

        export promote

    elif
        [ "$NODE2_IP" = "$master_cluster" ] && ([ $IS_NODE2_DOWN -eq 1 ] || [ "$NODE2_SERVICE_STAT" != "active" ])
    then
        echo -e "\n[ $date ] NODE2 IS MASTER AND DOWN"
        echo "[ $date ] Commencing Promote of NODE1..."
        promote+=1
        export master_cluster
        export IS_NODE1_DOWN
        export NODE1_SERVICE_STAT
        export replica_cluster
        export IS_NODE2_DOWN
        export NODE2_SERVICE_STAT

        export promote
    fi

}
