#!/bin/bash
promote_master() {
    FAIL=0

    date=$(date)

    color=$(tput setaf 111)
    echo ${color}

    REPLICA_SERVICE_STAT=$(ssh root@$replica_cluster systemctl is-active postgresql@12-main)
    if [ "$REPLICA_SERVICE_STAT" == "active" ]; then
        promote=$(ssh root@$replica_cluster sudo pg_ctlcluster 12 main promote)
        if [ $? -eq 0 ]; then
            echo "[ $date ] REPLICA AT $replica_cluster SUCCESSFULLY PROMOTED TO MASTER"
            replicaTo_master=1
        else
            echo -e "\n[ $date ] TRYING TO START POSTGRES SERVICE AT REPLICA"
            start_service=$(ssh root@$replica_cluster systemctl start postgresql@12-main)
            if [ $? -eq 0 ]; then
                echo "[ $date ] POSTGRES SERVICE AT REPLICA START SUCCESS"
                replicaTo_master=1
            else
                echo "[ $date ] POSTGRES SERVICE AT REPLICA START FAIL"
            fi
        fi
    fi

    if [[ $replicaTo_master -eq 1 ]]; then
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

        permission=$(ssh root@$master_cluster sudo chmod 700 -R /mnt/volume1/postgresql/12/main/)

        start_service=$(ssh root@$master_cluster systemctl start postgresql@12-main)
        if [ $? -eq 0 ]; then
            echo "[ $date ] POSTGRES SERVICE AT NEW REPLICA START SUCCESS"
            replicaTo_master=1
        else
            echo "[ $date ] POSTGRES SERVICE AT NEW REPLICA START FAIL"
        fi

    fi
}
