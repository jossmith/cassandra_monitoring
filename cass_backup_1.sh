#!/bin/bash
# read a node in the ring
startnode=$1
#Retrieves a list of all node ip addresses that are up
nodes=( $(nodetool -h ${startnode} status | grep 'UN' | awk '{print $2}'))
date=( $(date +%Y%M%d))
snapshotname=("${nodes[@]}")
snapshotname=(${snapshotname[@]//./})
# for debugging purposes
#for value in "${snapshotname[@]}" ; do    #print the new array 
#echo $value 
#done
#snapshotname=( "${snapshotname[@]/%/
cnt=${#snapshotname[@]}
for ((i=0;i<cnt;i++)); do
    snapshotname[i]="${snapshotname[i]}${date}"
    #echo "${snapshotname[i]}"
done

echo "Starting at:" 
index=0
while [ ${index} -lt ${#nodes[@]} ]
do
  echo "${snapshotname[index]}"
  #create snapshot with snapshotname name IP Address + date  ex 17221311020150513
  ssh -o "StrictHostKeyChecking no" ubuntu@${nodes[index]} "nodetool -h ${nodes[index]} snapshot -t ${snapshotname[index]}"
  #get directories that have snapshots in them 
  directory=( $(ssh -o "StrictHostKeyChecking no" ubuntu@${nodes[index]} "find /var/lib/cassandra/data -type d -name ${snapshotname[index]}"))
  #use directories to create file names
  directoryname=("${directory[@]}")
  directoryname=( "${directoryname[@]#/var/lib/cassandra/data/}" )
  directoryname=( "${directoryname[@]////_}" )
  #tar upload and delete 
  cnt3=${#directory[@]}
	for ((j=0;j<cnt3;j++)); do
		ssh -o "StrictHostKeyChecking no" ubuntu@${nodes[index]} "sudo mkdir /var/lib/cassandra/data/backups && sudo tar -Pcvzf /var/lib/cassandra/data/backups/${directoryname[j]}.tar.gz ${directory[j]} && aws s3 sync /var/lib/cassandra/data/backups/${directoryname[j]}.tar.gz s3://cass-useasttest/snapshot/ && sudo rm -f /var/lib/cassandra/data/backups/${directoryname[j]}.tar.gz && nodetool -h ${nodes[index]} cleanup"
	done
	
  index=$((index+1))
  echo "${nodes[index]} ended now"
done
wait
echo "Ended at:" 