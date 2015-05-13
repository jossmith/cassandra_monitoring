#!/bin/sh
nodes=( qtmcass1 qtmcass2 qtmcass16 qtmcass3 qtmcass4 qtmcass17 qtmcass5 qtmcass6 qtmcass18 qtmcass7 qtmcass8 qtmcass19 qtmcass9 qtmcass10 qtmcass20 qtmcass11 qtmcass12 qtmcass21 qtmcass13 qtmcass14 qtmcass15 )
outfile=/opt/cronscripts/deletemelater.log
tmpfile=/opt/cronscripts/deletemelator.log.tmp
date >> $outfile
daynum=$(date +"%j" | sed 's/0*//')
index=$((daynum%3))
while [ ${index} -lt ${#nodes[@]} ]
do
  echo "${nodes[index]}" >> $outfile
  nodetool repair -pr -h "${nodes[index]}" >> $outfile &
  index=$((index+3))
done
wait
date >> $outfile
mv $outfile $tmpfile
tail -n 10000 $tmpfile > $outfile
rm $tmpfile
