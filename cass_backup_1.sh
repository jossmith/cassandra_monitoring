#!/bin/bash
#initialize passed in parameters
# read a node in the ring
startnode=$1
bucket=$2
customer=$3

#setup log file
touch /var/lib/cassandra/data/backuplog.log
outfile=/var/lib/cassandra/data/backuplog.log

#Retrieves a list of all node ip addresses that are up
nodes=( $(/usr/bin/nodetool -h ${startnode} status | grep 'UN' | awk '{print $2}'))
date=( $(date +%Y%m%d))
snapshotname=("${nodes[@]}")
snapshotname=(${snapshotname[@]//./})

# for debugging purposes
#for value in "${nodes[@]}" ; do    #print the new array
#echo $value
#done
#snapshotname=( "${snapshotname[@]/%/
cnt=${#snapshotname[@]}

#create snapshot name
for ((i=0;i<cnt;i++)); do
    snapshotname[i]="${snapshotname[i]}${date}"
    #echo "${snapshotname[i]}"
done

echo "Starting at:" >> $outfile
date >> $outfile
index=0

while [ ${index} -lt ${#nodes[@]} ]
do
  echo "${snapshotname[index]}" >> $outfile

  #create snapshot with snapshotname name IP Address + date  ex 17221311020150513
  /usr/bin/ssh -i /home/ubuntu/.ssh/cassmon.pem -o "StrictHostKeyChecking no" cassmon@${nodes[index]} "nodetool clearsnapshot && nodetool snapshot -t ${snapshotname[index]}" >> $outfile

  #get directories that have snapshots in them
  directory=( $(/usr/bin/ssh -i /home/ubuntu/.ssh/cassmon.pem -o "StrictHostKeyChecking no" cassmon@${nodes[index]} "sudo find /var/lib/cassandra/data -type d -name ${snapshotname[index]}"))

  #use directories to create file names
  directoryname=("${directory[@]}") #copy to new array for manipulation
  directoryname=( "${directoryname[@]#/var/lib/cassandra/data/}" )  #remove beginning path
  directoryname=( "${directoryname[@]////_}" ) #change / to _

  # create backup directory if not exist
  /usr/bin/ssh -i /home/ubuntu/.ssh/cassmon.pem -o "StrictHostKeyChecking no" cassmon@${nodes[index]} "sudo mkdir -p 777 /var/lib/cassandra/data/backups"

  #tar upload and delete
  /usr/bin/ssh -i /home/ubuntu/.ssh/cassmon.pem -o "StrictHostKeyChecking no" cassmon@${nodes[index]} "nodetool disablethrift" >> $outfile
  cnt3=${#directory[@]}
        for ((j=0;j<cnt3;j++)); do
                /usr/bin/ssh -i /home/ubuntu/.ssh/cassmon.pem -o "StrictHostKeyChecking no" cassmon@${nodes[index]} "sudo tar -Pcpvzf /var/lib/cassandra/data/backups/${directoryname[j]}.tar.gz ${directory[j]}" >> $outfile
        done
  /usr/bin/ssh -i /home/ubuntu/.ssh/cassmon.pem -o "StrictHostKeyChecking no" cassmon@${nodes[index]} "nodetool enablethrift && aws s3 sync --sse /var/lib/cassandra/data/backups/ s3://$bucket/snapshot/$customer/$date/ && sudo rm -f /var/lib/cassandra/data/backups/*.tar.gz && nodetool clearsnapshot" >> $outfile
  uploadedcount=( $(/usr/bin/ssh -i /home/ubuntu/.ssh/cassmon.pem -o "StrictHostKeyChecking no" cassmon@${nodes[index]} "aws s3 ls s3://$bucket/snapshot/$customer/$date/ | grep ${snapshotname[index]} | grep "$(date +"%Y-%m-%d")" | wc -l"))
  echo ${#directory[@]}
  echo $uploadedcount
  if [ "${#directory[@]}" -ne "$uploadedcount" ]
    then
         echo "Failed a backup. Retrying all"
         /usr/bin/ssh -i /home/ubuntu/.ssh/cassmon.pem -o "StrictHostKeyChecking no" cassmon@${nodes[index]} "aws s3 sync --sse /var/lib/cassandra/data/backups/ s3://$bucket/snapshot/$customer/$date/" >> $outfile
  fi
  index=$((index+1))
  echo "${nodes[index]} ended now" >> $outfile
done
wait
echo "Ended at:" >> $outfile
date >> $outfile
