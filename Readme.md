## DB Migration

## To run docker container:

    step-1:
        check if the file has docker-compose.yml file
    
    step-2:
        docker-compose up -d

## Modify the Connecting string in migrate.sh:

    container_id="docker container id"
    host="host"
    username="User name"
    DB_name="DB name"
    schema="Schema name"
    TEMP_WORK_PATH="./tmp"
    BACKUP_ROOT_PATH="./backup" # This is where your *.sql files will be exported at

## Modify the Connecting string in import_to_db.sh:

    container_id="docker container id"
    host="host"
    username="User name"
    DB_name="DB name"
    schema="Schema name"
    local_filepath=./backup/ # This is where your *.sql files will be exported at
    docker_filepath=/tmp/backup # This is where your *.sql files will be stored in docker

## Folder Structure:
    backup
        -functions
        -sequence
        -storedprocedures
        -tables
        -triggerfunction
        -triggers
        -views

## Import .sql file from DB:

    step-1:
        Modify the connection string to connect DB

    step-2:
        bash migrate.sh

## Export .sql file to DB:

    step-1:
        Check if the .sql file in ./backup/(individual folders)/
    
    step-2:
        It copies local files to docker files (docker cp ) # check if file_path is vaild
    
    step-3:
        bash import_to_db.sh
