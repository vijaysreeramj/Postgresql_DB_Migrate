#! /bin/bash


container_id=5e3764ab6231
host=localhost
username=postgres
DB_name=check
# schema=public
password=postgres
port=5432
local_filepath=./backup/
docker_filepath=/tmp/backup
folders=("sequence" "tables" "views" "functions" "triggerfunction" "storedprocedures" "triggers")
docker exec $container_id rm -r $docker_filepath

docker cp $local_filepath $container_id:$docker_filepath


for entry in ${folders[@]};
do
  filesToLoad=$(docker exec $container_id find $docker_filepath/$entry -maxdepth 1 -type f  -name  "*.sql")
  for filepath in $filesToLoad
  do
  docker exec $container_id psql postgresql://$username:$password@$host:$port/$DB_name -f $filepath
#   echo $filepath
  done
done

