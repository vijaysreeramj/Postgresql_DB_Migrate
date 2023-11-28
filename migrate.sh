#! /bin/bash
#docker exec  postgresql  bash

### CHANGE THESE TO YOUR SERVER/APP INFO ###
container_id=5e3764ab6231
host=localhost
username=postgres
DB_name=postgres
schema=public
password=postgres
port=5432
TEMP_WORK_PATH="./tmp"
BACKUP_ROOT_PATH="./backup" # This is where your *.sql files will be exported at

### END CONFIGURATION ###

[ -d $TEMP_WORK_PATH ] || mkdir -p $TEMP_WORK_PATH
rm -rf $TEMP_WORK_PATH/*

[ -d $BACKUP_ROOT_PATH ] || mkdir -p $BACKUP_ROOT_PATH
rm -rf $BACKUP_ROOT_PATH/*

mkdir $BACKUP_ROOT_PATH/tables
mkdir $BACKUP_ROOT_PATH/functions
mkdir $BACKUP_ROOT_PATH/storedprocedures
mkdir $BACKUP_ROOT_PATH/triggers
mkdir $BACKUP_ROOT_PATH/sequence
mkdir $BACKUP_ROOT_PATH/triggerfunction
mkdir $BACKUP_ROOT_PATH/views

echo "Export table ..."
for table in $(docker exec $container_id  psql postgresql://$username:$password@$host:$port/$DB_name -t -c  "Select table_name from information_schema.tables where table_schema='$schema' and table_type = 'BASE TABLE';");
do docker exec $container_id  pg_dump  postgresql://$username:$password@$host:$port/$DB_name -t $table| grep -v TRIGGER > $BACKUP_ROOT_PATH/tables/$table.sql;
done;

echo "Export view ..."
for views in $(docker exec $container_id  psql postgresql://$username:$password@$host:$port/$DB_name -t -c  "Select table_name from INFORMATION_SCHEMA.views where table_schema = '$schema';");
do docker exec $container_id  pg_dump  postgresql://$username:$password@$host:$port/$DB_name -t $views  > $BACKUP_ROOT_PATH/views/$views.sql;
done;

echo "Export functions..."
docker exec $container_id psql postgresql://$username:$password@$host:$port/$DB_name -t -c "select pg_get_functiondef(p.oid)from pg_proc p left join pg_namespace n on p.pronamespace = n.oid left join pg_language l on p.prolang = l.oid left join pg_type t on t.oid = p.prorettype where n.nspname not in ('pg_catalog', 'information_schema') and p.prokind = 'f'" > $TEMP_WORK_PATH/db_functions.sql
# echo "Exporting stored functions..."
currectDirectory=$(pwd)
cd $TEMP_WORK_PATH
csplit -f function -b '%d.sql' db_functions.sql '/FUNCTION/' '{*}'
cd $currectDirectory
counter=1
while [ -f $TEMP_WORK_PATH/function$counter.sql ]
do
  name=$(head -1 $TEMP_WORK_PATH/function$counter.sql | awk {'print $5'})
  sed -E 's/\+$//g' $TEMP_WORK_PATH/function$counter.sql > $TEMP_WORK_PATH/newfunction$counter.sql
  name=$(echo $name | cut -d "." --f 2 | cut -d "(" --f 1)
  
  if [[ $(grep -rnwl $TEMP_WORK_PATH/newfunction$counter.sql -e 'RETURNS trigger') ]];
  then
    mv $TEMP_WORK_PATH/newfunction$counter.sql $BACKUP_ROOT_PATH/triggerfunction/$name.sql
    counter=$((counter+1))
  else
   mv $TEMP_WORK_PATH/newfunction$counter.sql $BACKUP_ROOT_PATH/functions/$name.sql
  counter=$((counter+1))
  fi
done
rm -r $TEMP_WORK_PATH

echo "Export stored procedure..."
[ -d $TEMP_WORK_PATH ] || mkdir -p $TEMP_WORK_PATH
rm -rf $TEMP_WORK_PATH/*
docker exec $container_id psql postgresql://$username:$password@$host:$port/$DB_name -t -c "select  pg_get_functiondef(p.oid)from pg_proc p left join pg_namespace n on p.pronamespace = n.oid left join pg_language l on p.prolang = l.oid left join pg_type t on t.oid = p.prorettype where n.nspname not in ('pg_catalog', 'information_schema') and p.prokind = 'p'" > $TEMP_WORK_PATH/db_functions.sql
# echo "Exporting stored functions..."
currectDirectory=$(pwd)
cd $TEMP_WORK_PATH
csplit -f function -b '%d.sql' db_functions.sql '/PROCEDURE/' '{*}'
cd $currectDirectory
counter=1
while [ -f $TEMP_WORK_PATH/function$counter.sql ]
do
  name=$(head -1 $TEMP_WORK_PATH/function$counter.sql | awk {'print $5'})
  sed -E 's/\+$//g' $TEMP_WORK_PATH/function$counter.sql > $TEMP_WORK_PATH/newfunction$counter.sql
  name=$(echo $name | cut -d "." --f 2 | cut -d "(" --f 1)
  mv $TEMP_WORK_PATH/newfunction$counter.sql $BACKUP_ROOT_PATH/storedprocedures/$name.sql
  counter=$((counter+1))
done
rm -r $TEMP_WORK_PATH


echo "Export Triggers"
[ -d $TEMP_WORK_PATH ] || mkdir -p $TEMP_WORK_PATH
rm -rf $TEMP_WORK_PATH/*
 docker exec $container_id  pg_dump postgresql://$username:$password@$host:$port/$DB_name > $TEMP_WORK_PATH/db_function.sql
 grep -i "CREATE TRIGGER" $TEMP_WORK_PATH/db_function.sql > $TEMP_WORK_PATH/db_functions.sql
echo "Exporting stored functions..."
currectDirectory=$(pwd)
cd $TEMP_WORK_PATH
csplit -f function -b '%d.sql' db_functions.sql '/CREATE TRIGGER/' '{*}'
cd $currectDirectory
counter=1
while [ -f $TEMP_WORK_PATH/function$counter.sql ]
do
  name=$(head -1 $TEMP_WORK_PATH/function$counter.sql | awk {'print $3'})
  name=$(echo $name | cut -d "." --f 2 | cut -d "(" --f 1)
  mv $TEMP_WORK_PATH/function$counter.sql $BACKUP_ROOT_PATH/triggers/$name.sql
  counter=$((counter+1))
done
rm -r $TEMP_WORK_PATH

echo "Export Sequence"
for sequence in $(docker exec $container_id  psql postgresql://$username:$password@$host:$port/$DB_name -t -c  "select sequence_name from information_schema.sequences where sequence_schema = 'public'");
do
docker exec $container_id pg_dump postgresql://$username:$password@$host:$port/$DB_name -t $sequence > $BACKUP_ROOT_PATH/sequence/$sequence.sql;
done
