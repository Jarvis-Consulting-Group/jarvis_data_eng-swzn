#!/bin/bash

dirname=""

if [ $# -eq 2 ] && [ $1 == "-d" ]; then
    dirname="$2"

elif [ $# -eq 0 ]; then 
    dirname="cluster_management"

else
    echo "Wrong usage!"
    echo "Correct usage: bash setup.sh [-d directory name]"
    exit 0;
fi

mkdir "$dirname"
mkdir "$dirname/scripts" "$dirname/sql"

touch "$dirname/scripts/host_info.sh" "$dirname/scripts/host_usage.sh" "$dirname/scripts/psql_docker.sh"
chmod +x "$dirname/scripts/host_info.sh" "$dirname/scripts/host_usage.sh" "$dirname/scripts/psql_docker.sh"

touch "$dirname/sql/ddl.sql"

echo "CREATE TABLE IF NOT EXISTS PUBLIC.host_info 
( 
    id               SERIAL NOT NULL, 
    hostname         VARCHAR NOT NULL, 
    cpu_number       INT2 NOT NULL, 
    cpu_architecture VARCHAR NOT NULL, 
    cpu_model        VARCHAR NOT NULL, 
    cpu_mhz          FLOAT8 NOT NULL, 
    l2_cache         INT4 NOT NULL, 
    "timestamp"      TIMESTAMP NULL, 
    total_mem        INT4 NULL, 
    CONSTRAINT host_info_pk PRIMARY KEY (id), 
    CONSTRAINT host_info_un UNIQUE (hostname) 
);

CREATE TABLE IF NOT EXISTS PUBLIC.host_usage 
( 
    "timestamp"    TIMESTAMP NOT NULL, 
    host_id        SERIAL NOT NULL, 
    memory_free    INT4 NOT NULL, 
    cpu_idle       INT2 NOT NULL, 
    cpu_kernel     INT2 NOT NULL, 
    disk_io        INT4 NOT NULL, 
    disk_available INT4 NOT NULL, 
    CONSTRAINT host_usage_host_info_fk FOREIGN KEY (host_id) REFERENCES 
    host_info(id) 
);
" > "$dirname/sql/ddl.sql"

info_script=$(
    cat << EOF
#!/bin/bash 

psql_host=\$1
psql_port=\$2
db_name=\$3
psql_user=\$4
psql_password=\$5


if [ \$# -ne 5 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

# Saving system output
vm_cpu_out=\$(vmstat --unit M)
lscpu_out=\$(lscpu)
vm_disk_out=\$(vmstat --unit M -d)
df_disk_out=\$(df -BM /)
timestamp=\$(date --utc -u '+%Y-%m-%d %H:%M:%S')

# Constructing input values
hostname=\$(hostname -f)
cpu_number=\$(echo "\$lscpu_out"  | egrep "^CPU\(s\):" | awk '{print \$2}' | xargs)
cpu_architecture=\$(echo "\$lscpu_out"  | egrep "^Architecture:" | awk '{print \$2}' | xargs)
cpu_model=\$(echo "\$lscpu_out"  | egrep "^Model:" | awk '{print \$2}' | xargs)
cpu_mhz=\$(echo "\$lscpu_out"  | egrep "^CPU MHz" | awk '{print \$3}' | xargs)
l2_cache=\$(echo "\$lscpu_out"  | egrep "^L2" | awk '{print \$3}' | sed 's/K//' |xargs)
total_mem=\$(echo "\$vm_cpu_out" | tail -1 | awk '{print \$4}')
timestamp=\$(date --utc -u '+%Y-%m-%d %H:%M:%S')

# Finding autogenerated id from table
host_id="(SELECT id FROM host_info WHERE hostname='\$hostname');"

insert_statement="INSERT INTO 
host_info(hostname, cpu_number, cpu_architecture, cpu_model, cpu_mhz, l2_cache, timestamp, total_mem) 
VALUES ('\$hostname', \$cpu_number, '\$cpu_architecture', '\$cpu_model', \$cpu_mhz, \$l2_cache, '\$timestamp', \$total_mem);"

#set up env var for pql cmd
export PGPASSWORD=\$psql_password 
#Insert date into a database
psql -h \$psql_host -p \$psql_port -d \$db_name -U \$psql_user -c "\$insert_statement"
exit \$?
EOF
)

usage_script=$(
    cat << EOF
#!/bin/bash

psql_host=\$1
psql_port=\$2
db_name=\$3
psql_user=\$4
psql_password=\$5


if [ \$# -ne 5 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

# Saving system output
vm_cpu_out=\$(vmstat --unit M)
lscpu_out=\$(lscpu)
vm_disk_out=\$(vmstat --unit M -d)
df_disk_out=\$(df -BM /)
timestamp=\$(date --utc -u '+%Y-%m-%d %H:%M:%S')

# Constructing input values
hostname=\$(hostname -f)
memory_free=\$(echo "\$vm_cpu_out" | tail -1 | awk -v col="4" '{print \$col}')
cpu_idle=\$(echo "\$vm_cpu_out" | tail -1 | awk -v col="15" '{print \$col}')
cpu_kernel=\$(echo "\$vm_cpu_out" | tail -1 | awk -v col="14" '{print \$col}')
disk_io=\$(echo "\$vm_disk_out"| tail -1 | awk -v col="10" '{print \$col}')
disk_available=\$(echo "\$df_disk_out"| tail -1 | awk -v col="4" '{print \$col}' | sed 's/M//')

# Finding autogenerated id from table
host_id="(SELECT id FROM host_info WHERE hostname='\$hostname')"

insert_statement="INSERT INTO host_usage(timestamp,host_id,memory_free,cpu_idle,cpu_kernel,disk_io,disk_available) VALUES ('\$timestamp',\$host_id,\$memory_free,\$cpu_idle,\$cpu_kernel,\$disk_io,\$disk_available);"

#set up env var for pql cmd
export PGPASSWORD=\$psql_password 
#Insert date into a database
psql -h \$psql_host -p \$psql_port -d \$db_name -U \$psql_user -c "\$insert_statement"
exit \$?
EOF
)

psql_script=$(cat << EOF 
#! /bin/bash

cmd=\$1 #First argument (start | stop | create)
db_username=\$2 #db_username
db_password=\$3 #db_password

# {a} || {b}, if {a} fails run {b}
sudo systemctl status docker || systemctl start docker

docker container inspect jrvs-psql
container_status=\$? #returns 0 if exists, 1 if not exists

#User switch case to handle create|stop|start opetions
case \$cmd in 
  create)
  
  # If the exit status of the inspect command is 0, then the container exists
  if [ \$container_status -eq 0 ]; then
		echo 'Container already exists'
		exit 1	
	fi

  # If we have not received exactly 3 args, we're missing username and/or password
  if [ \$# -ne 3 ]; then
    echo 'Create requires username and password'
    exit 1
  fi
  
	docker volume create pgdata
	docker run --name jrvs-psql -e POSTGRES_PASSWORD=\$db_password -e POSTGRES_USERNAME=\$db_username -d -v "jrvs-psql:/var/lib/postgresql/data" -p 5432:5432 postgres:9.6-alpine
	exit \$?
	;;

  start|stop) 
  #check instance status; exit 1 if container has not been created
  if [ \$container_status -eq 1 ]; then
        echo 'Container does not exist'
		exit 1	
  fi

  #Start or stop the container
	docker container \$cmd jrvs-psql
	exit \$?
	;;	
  
  *)
	echo 'Illegal command'
	echo 'Commands: start|stop|create'
	exit 1
	;;
esac 
EOF
)

echo "$info_script" > "$dirname/scripts/host_info.sh"
echo "$usage_script" > "$dirname/scripts/host_usage.sh"
echo "$psql_script" > "$dirname/scripts/psql_docker.sh"

if [ "$info_script" == "$(cat $dirname/scripts/host_info.sh)" ] && [ "$usage_script" == "$(cat $dirname/scripts/host_usage.sh)" ] && [ "$psql_script" == "$(cat $dirname/scripts/psql_docker.sh)" ] ; then
    echo "Setup successful"
    exit 0
fi

echo "Setup unsuccessful, consider cloning code from GitHub repo: https://github.com/Jarvis-Consulting-Group/jarvis_data_eng-swzn/"
exit $?