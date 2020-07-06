#!/bin/bash

. /usr/lib/nagios/plugins/utils.sh

abs() { 
    [[ $[ $@ ] -lt 0 ]] && echo "$[ ($@) * -1 ]" || echo "$[ $@ ]"
}

diff_warn=$2
diff_crit=$3

tmpx=$(mktemp)

function finish {
   rm -f $tmpx
}
trap finish EXIT

cat>$tmpx<<EOF
<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:shibmeta="urn:mace:shibboleth:metadata:1.0"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
                xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
                xmlns:exsl="http://exslt.org/common"
                extension-element-prefixes="exsl"
                xmlns:xi="http://www.w3.org/2001/XInclude"
                xmlns:shibmd="urn:mace:shibboleth:metadata:1.0">

  <xsl:output method="text" indent="yes" encoding="UTF-8"/>

  <xsl:template match="md:EntitiesDescriptor">
    <xsl:value-of select="@validUntil"/>
  </xsl:template>

</xsl:stylesheet>
EOF

dstr=$(wget -qO- $1 | xsltproc $tmpx -)
if [ $? -ne 0 ]; then
   echo "CRITICAL - Service $1 FAIL"
   echo $status
   exit $STATE_CRITICAL
fi

exp=$(date -d $dstr +%s)
now=$(date +%s)

d=$(expr $exp - $now)
if [ $d -lt $diff_crit ]; then
   echo "CRITICAL - metadata in $1 expires in $d seconds"
   echo $status
   exit $STATE_CRITICAL
elif [ $d -lt $diff_warn ]; then
   echo "WARNING - metadata in $1 expires in $d seconds"
   echo $status
   exit $STATE_WARNING
else
   echo "OK - metadata in $1 expires in $d seconds"
   echo $status
   exit $STATE_OK
fi
