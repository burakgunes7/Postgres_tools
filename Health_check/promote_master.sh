#!/bin/bash
promote_master() {
    FAIL=0

    date=$(date)

    color=$(tput setaf 111)
    echo ${color}

    # NODE 1 IS DOWN BUT NODE 2 IS UP || NODE 1 IS UP BUT SERVICE IS DOWN
    #
    promote=$(ssh root@$replica_cluster sudo pg_ctlcluster 12 main promote)
    if [ $? -eq 0 ]; then
        echo "[ $date ] REPLICA at $replica_cluster successfully promoted to MASTER"
        replicaTo_master=1
    else
        echo "[ $date ] REPLICA at $replica_cluster failed to be promoted to MASTER"
    fi

    if [ $replicaTo_master -eq 1 ]; then
        remove_main_folder=$(ssh root@$master_cluster sudo rm -rf /mnt/volume1)
        if [ $? -eq 0 ]; then
            echo "[ $date ] POSTGRES REMOVE FOLDER OK"
        else
            echo "[ $date ]  POSTGRES REMOVE FOLDER FAIL"
        fi

        create_main_folder=$(ssh root@$master_cluster mkdir -p /mnt/volume1/postgresql/12/main/)
        if [ $? -eq 0 ]; then
            echo "[ $date ] POSTGRES CREATE FOLDER OK"
        else
            echo "[ $date ] POSTGRES CREATE FOLDER FAIL"
        fi

        ownership=$(ssh root@$master_cluster chown -R postgres:postgres /mnt/)

        base_backup=$(
            ssh postgres@$master_cluster pg_basebackup -h $replica_cluster -D /mnt/volume1/postgresql/12/main/ -U replicator -P -v -R -X stream -C -S slaveslot1
        )
        if [ $? -eq 0 ]; then
            echo "[ $date ] POSTGRES BACKUP SLAVESLOT1 OK"
        else
            echo "[ $date ] POSTGRES BACKUP SLAVESLOT1 FAIL"
        fi

        start_service=$(ssh root@$master_cluster systemctl start postgresql@12-main)
        if [ $? -eq 0 ]; then
            echo "[ $date ] POSTGRES SERVICE START OK"
        else
            echo "[ $date ] POSTGRES SERVICE START FAIL"
        fi

        permission=$(ssh root@$master_cluster sudo chmod 700 -R /mnt/volume1/postgresql/12/main/)

        conf_reload=$(ssh root@$master_cluster pg_ctlcluster 12 main reload)
    fi
}
