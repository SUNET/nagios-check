#!/bin/bash

set +x

. /usr/lib/nagios/plugins/utils.sh

abs() { 
    [[ $[ $@ ] -lt 0 ]] && echo "$[ ($@) * -1 ]" || echo "$[ $@ ]"
}

tmpx=$(mktemp)

finish() {
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
                xmlns:eidas="http://eidas.europa.eu/saml-extensions"
                xmlns:shibmd="urn:mace:shibboleth:metadata:1.0">

  <xsl:output method="text" indent="yes" encoding="UTF-8"/>

  <xsl:template match="md:EntitiesDescriptor"><xsl:apply-templates select="//eidas:NodeCountry"/></xsl:template>

  <xsl:template match="eidas:NodeCountry">
    <xsl:value-of select="text()"/><xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="*"></xsl:template>

</xsl:stylesheet>
EOF

missing() {
   m=""
   for x in $1; do
      echo $2 | grep -q $x || m="$m $x"
   done
   echo $m
}

list=$(wget -qO- https://$1/role/idp.xml | xsltproc $tmpx -)
if [ $? -ne 0 ]; then
   echo "CRITICAL - Service FAIL"
   echo $status
   exit $STATE_CRITICAL
fi

list_expected=$2
list_missing=$(missing "$list_expected" "$list")
count=$(echo $list_missing | wc -w)
count_diff_warn=$3
count_diff_crit=$4

if [ $count -ge $count_diff_crit ]; then
   echo "CRITICAL - $count countries missing: $list_missing"
   echo $status
   exit $STATE_CRITICAL
elif [ $count -ge $count_diff_warn ]; then
   echo "WARNING - $count countries missing: $list_missing"
   echo $status
   exit $STATE_WARNING
else
   echo "OK - Service healthy"
   echo $status
   exit $STATE_OK
fi
