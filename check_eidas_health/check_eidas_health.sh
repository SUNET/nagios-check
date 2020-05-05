#!/bin/bash

. /usr/lib/nagios/plugins/utils.sh

status=`wget --no-check-certificate -qO- https://$1:444/manage/health`
echo $status | jq -r '.status' | grep -q "UP"
if [ $? -ne 0 ]; then
   echo "CRITICAL - Service FAIL"
   echo $status
   exit $STATE_CRITICAL
else
   echo "OK - Service healthy"
   echo $status
   exit $STATE_OK
fi
