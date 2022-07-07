export $(grep -v '^#' .env | xargs)

for IP in $NODE*_IP; do
    echo $NODE*_IP
done

/home/turkai/Desktop/Postgres/Health_check/health_check.sh
