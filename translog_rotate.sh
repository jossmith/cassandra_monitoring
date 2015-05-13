#!/bin/sh
sendrequired=''
outfile=translog_outfile.mail
emails="AutomatedAlertsForSearchDevelopment@careerbuilder.com"
subject="[Production Alert] Transaction log failed to create/reap"
statuscode=`curl -s -w "%{http_code}\\n" cbcassweb01/utils/create_translog?devkey=LetMeIn -o /dev/null`
if [ $statuscode != '200' ]; then
        sendrequired=true
fi

if [ $sendrequired ]; then

  touch $outfile
  curl -s cbcassweb01/utils/create_translog?devkey=LetMeIn >> $outfile

  ruby /opt/search/PagerDuty/PagerDutyModule.rb "High" "$subject" "$(cat $outfile)" "cassandraadmin@opscenter01" "text"
  rm $outfile

fi
