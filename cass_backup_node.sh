#!/bin/bash

PROGNAME=$(basename $0)

function error_exit
{

#	----------------------------------------------------------------
#	Function for exit due to fatal program error
#		Accepts 1 argument:
#			string containing descriptive error message
#	----------------------------------------------------------------


	aws ses send-email --from CassandraMonitor@cbsitedb.net --destination ToAddresses="josh.smith@careerbuilder.com" --subject "Cassandra backup went wrong!" --text "$HOSTNAME ${PROGNAME}: ${1:-"Unknown Error"}"
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	exit 1
}


snapshotname=$1
bucket=$2
customer=$3

sudo touch /var/lib/cassandra/data/backuplog.log
sudo chmod 666 /var/lib/cassandra/data/backuplog.log
outfile=/var/lib/cassandra/data/backuplog.log

date=( $(date +%Y%m%d))

#snapshotname=$snapshotname$date

echo "Starting at:" >> $outfile
date >> $outfile

nodetool clearsnapshot && nodetool snapshot -t $snapshotname && sudo mkdir -p 777 /var/lib/cassandra/data/backups && nodetool disablethrift

directory=( $(sudo find /var/lib/cassandra/data -type d -name $snapshotname))

#use directories to create file names
directoryname=("${directory[@]}") #copy to new array for manipulation
directoryname=("${directoryname[@]#/var/lib/cassandra/data/}")  #remove beginning path
directoryname=("${directoryname[@]////_}") #change / to _

cnt3=${#directory[@]}
for ((j=0;j<cnt3;j++)); do
    sudo tar -Pcpvzf /var/lib/cassandra/data/backups/${directoryname[j]}.tar.gz ${directory[j]} >> $outfile
done
	
nodetool enablethrift && aws s3 sync --sse /var/lib/cassandra/data/backups/ s3://$bucket/snapshot/$customer/$date/ && nodetool clearsnapshot >> $outfile

uploadedcount=( $(aws s3 ls s3://$bucket/snapshot/$customer/$date/ | grep $snapshotname | grep "$(date +"%Y-%m-%d")" | wc -l))
echo ${#directory[@]}
echo $uploadedcount
if [ "${#directory[@]}" -ne "$uploadedcount" ]
    then
        echo "Failed a backup. Retrying all" >> $outfile
		aws s3 sync --sse /var/lib/cassandra/data/backups/ s3://$bucket/snapshot/$customer/$date/ >> $outfile
    fi
	
sudo rm -f /var/lib/cassandra/data/backups/*.tar.gz 

echo "Ended at:" >> $outfile
date >> $outfile