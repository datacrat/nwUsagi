#!/bin/bash
#
# nwuHead.sh
#
# (c) 2020 datacrat

# Load library shell
NWUBASE=/var/lib/nwusagi
NWULIBSH=${NWUBASE}/bin/nwulib.sh
if [ ! -f ${NWULIBSH} ]; then
    echo "${NWULIBSH} is not accessible. Exiting." >&2
    exit 1
fi
. ${NWULIBSH}
#

if [ $# -lt 2 ]; then
    PERROR "Usage: $0 <SNMP community> <host>"
    exit 1
fi

COMMUNITY=$1
TARGETIP=$2

SNMPGET=$(which snmpget)
if [ $? -ne 0 ]; then
    PERROR "Cannot find snmpget. Exiting."
    exit 1
fi

SNMPWALK=$(which snmpwalk)
if [ $? -ne 0 ]; then
    PERROR "Cannot find snmpwalk. Exiting."
    exit 1
fi

mkdir ${WORKDIR}
if [ $? -ne 0 ]; then
    PERROR "Could not create ${WORKDIR}. Exiting."
    exit 1
fi

ifIndex=1.3.6.1.2.1.2.2.1.1
${SNMPWALK} -OQ -Ov -v2c -c ${COMMUNITY} ${TARGETIP} ${ifIndex} > ${WORKDIR}/ifIndexList
if [ $? -ne 0 ]; then
    PERROR "Could not poll ifIndex from ${TARGETIP}. Exiting."
    exit 1
fi

ifDescr=1.3.6.1.2.1.2.2.1.2
ifAlias=1.3.6.1.2.1.31.1.1.1.18
for idx in $(cat ${WORKDIR}/ifIndexList)
do
    descr=$(${SNMPGET} -OQ -Ov -v2c -c ${COMMUNITY} ${TARGETIP} ${ifDescr}.${idx})
    if [ $? -ne 0 ]; then
	PERROR "Could not poll ifDescr for ${idx}. Exiting."
	rm -rf ${WORKDIR}
	exit 1
    fi
    alias=$(${SNMPGET} -OQ -Ov -v2c -c ${COMMUNITY} ${TARGETIP} ${ifAlias}.${idx})
    if [ $? -ne 0 ]; then
	PERROR "Could not poll ifAlias for ${idx}. Exiting."
	rm -rf ${WORKDIR}
	exit 1
    fi
    echo "${descr}(${alias})" >> ${WORKDIR}/ifNames
done

echo -n "Timestamp"
awk '{ printf "\t[IN]%s", $0; }' ${WORKDIR}/ifNames
awk '{ printf "\t[OUT]%s", $0; }' ${WORKDIR}/ifNames
echo

rm -rf ${WORKDIR}

# bottom of file
