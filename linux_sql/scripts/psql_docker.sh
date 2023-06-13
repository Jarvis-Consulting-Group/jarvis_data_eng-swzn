#! /bin/bash


cmd=$1 #First argument (start | stop | create)
db_username=$2 #db_username
db_password=$3 #db_password

# {a} || {b}, if {a} fails run {b}
sudo systemctl status docker || systemctl start docker

docker container inspect jrvs-psql
container_status=$? #returns 0 if exists, 1 if not exists

#User switch case to handle create|stop|start opetions
case $cmd in 
  create)
  
  # If the exit status of the inspect command is 0, then the container exists
  if [ $container_status -eq 0 ]; then
		echo 'Container already exists'
		exit 1	
	fi

  # If we have not received exactly 3 args, we're missing username and/or password
  if [ $# -ne 3 ]; then
    echo 'Create requires username and password'
    exit 1
  fi
  
	docker volume create pgdata
	docker run --name jrvs-psql -e POSTGRES_PASSWORD=$db_password -e POSTGRES_USERNAME=$db_username -d -v "jrvs-psql:/var/lib/postgresql/data" -p 5432:5432 postgres:9.6-alpine
	exit $?
	;;

  start|stop) 
  #check instance status; exit 1 if container has not been created
  if [ $container_status -eq 1 ]; then
        echo 'Container does not exist'
		exit 1	
  fi

  #Start or stop the container
	docker container $cmd jrvs-psql
	exit $?
	;;	
  
  *)
	echo 'Illegal command'
	echo 'Commands: start|stop|create'
	exit 1
	;;
esac 