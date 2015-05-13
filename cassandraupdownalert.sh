#!/bin/sh

priority="Normal"
threshold=1
highthreshold=2
nodetooloutput=''
sendrequired=''
highsendrequired=''
outfile=updown_outfile.mail
emails="SearchDevelopment@careerbuilder.com;SiteDBAlerts@careerbuilder.com"
subject="Cassandra service down"

function DetermineIfDownIsOverThreshold() {
        if [ $numdown -ge $threshold ]; then
                sendrequired=true
                if [ $numdown -ge $highthreshold ]; then
                        highsendrequired=true
                fi
        fi

        if [ $sendrequired ]; then
                touch $outfile
                echo 'To:'"$emails"'' > $outfile
                echo 'From:'cassandraadmin'@'opscenter01.atl.careerbuilder.com'' >> $outfile
                echo 'Subject:'"$subject"'' >> $outfile
                if [ $highsendrequired ]; then
                        echo 'Importance:High' >> $outfile
                fi
                date >> $outfile
                echo "" >> $outfile
                echo "$nodetooloutput" >> $outfile
                #cat $outfile
                /usr/sbin/sendmail -t < $outfile
                #rm $outfile
        fi
}

function DetermineIfDownIsOverThresholdV2() {
        if [ $numdown -ge $threshold ]; then
                sendrequired=true
                if [ $numdown -ge $highthreshold ]; then
                        priority="High"
                fi
        fi

        if [ $sendrequired ]; then
                touch $outfile
                date >> $outfile
                echo "" >> $outfile
                echo "$nodetooloutput" >> $outfile

                sudo rm $outfile
        fi
}


nodetooloutput=`nodetool status -h qtmcass2`
numdown=`echo "$nodetooloutput" | grep DN | wc -l`
numup=`echo "$nodetooloutput" | grep UN | wc -l`

if [ $numup -eq 0 ]; then
        nodetooloutput=`nodetool status -h qtmcass12`
        numdown=`echo "$nodetooloutput" | grep DN | wc -l`
        numup=`echo "$nodetooloutput" | grep UN | wc -l`

        if [ $numup -eq 0 ]; then
                subject="All nodes are down!"
                sendrequired=true
                highsendrequired=true
        fi
fi

DetermineIfDownIsOverThresholdV2
