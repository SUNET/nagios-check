#!/bin/bash

. /usr/lib/nagios/plugins/utils.sh

abs() { 
    [[ $[ $@ ] -lt 0 ]] && echo "$[ ($@) * -1 ]" || echo "$[ $@ ]"
}

count=$(wget -qO- https://$1/role/idp.xml | xmllint --format - | grep eidas:NodeCountry | wc -l)
if [ $? -ne 0 ]; then
   echo "CRITICAL - Service FAIL"
   echo $status
   exit $STATE_CRITICAL
fi

count_expected=$2
count_diff_warn=$3
count_diff_crit=$4

d=$(abs $count - $count_expected)
if [ $d -ge $count_diff_crit ]; then
   echo "CRITICAL - country count is $count expected $count_expected"
   echo $status
   exit $STATE_CRITICAL
elif [ $d -ge $count_diff_warn ]; then
   echo "WARNING - country count is $count expected $count_expected"
   echo $status
   exit $STATE_WARNING
else
   echo "OK - Service healthy ($count countries)"
   echo $status
   exit $STATE_OK
fi
