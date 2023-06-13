lscpu_out=$(lscpu)
vm_cpu_out=$(vmstat --unit M)
vm_disk_out=$(vmstat --unit M -d)
df_disk_out=$(df -BM /)

#hardware info
hostname=$(hostname -f)
cpu_number=$(echo "$lscpu_out"  | egrep "^CPU\(s\):" | awk '{print $2}' | xargs)
cpu_architecture=$(echo "$lscpu_out"  | egrep "^Architecture:" | awk '{print $2}' | xargs)
cpu_model=$(echo "$lscpu_out"  | egrep "^Model:" | awk '{print $2}' | xargs)
cpu_mhz=$(echo "$lscpu_out"  | egrep "^CPU MHz:" | awk '{print $2}' | xargs)
l2_cache=$(echo "$lscpu_out"  | egrep "^L2 cache:" | awk '{print $2}' | xargs)
total_mem=$(echo "$vm_cpu_out" | tail -1 | awk '{print $4}')
timestamp=$(date --utc -u '+%Y-%m-%d %H:%M:%S')

#usage info
memory_free=$(echo "$vm_cpu_out" | tail -1 | awk -v col="4" '{print $col}')
cpu_idle=$(echo "$vm_cpu_out" | tail -1 | awk -v col="15" '{print $col}')
cpu_kernel=$(echo "$vm_cpu_out" | tail -1 | awk -v col="14" '{print $col}')
disk_io=$(echo "$vm_disk_out"| tail -1 | awk -v col="10" '{print $col}')
disk_available=$(echo "$df_disk_out"| tail -1 | awk -v col="4" '{print $col}')