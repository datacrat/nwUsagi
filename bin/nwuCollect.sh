#!/bin/bash
#
# nwuCollect.sh
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

if [ $# -lt 1 ]; then
    PERROR "Usage: $0 <device>"
    exit 1
fi

device=$1
targetip=$(awk -F '\t' -v devname=${device} '{if ($1==devname) print $2}' ${DEVLISTFILE})
community=$(awk -F '\t' -v devname=${device} '{if ($1==devname) print $3}' ${DEVLISTFILE})
if [ -z "${targetip}" ]; then
    PERROR "Coudn't find the entry: ${device}. Exiting."
    exit 1
fi

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
${SNMPWALK} -OQ -Ov -v2c -c ${community} ${targetip} ${ifIndex} > ${WORKDIR}/ifIndexList
if [ $? -ne 0 ]; then
    PERROR "Could not poll ifIndex from ${TARGETIP}. Exiting."
    rm -rf ${WORKDIR}
    exit 1
fi

ifInOctets=1.3.6.1.2.1.2.2.1.10
for idx in $(cat ${WORKDIR}/ifIndexList)
do
    ${SNMPGET} -OQ -Ov -v2c -c ${community} ${targetip} ${ifInOctets}.${idx} >> ${WORKDIR}/ifInOctets
    if [ $? -ne 0 ]; then
	PERROR "Could not poll ifInOctets for ${idx}. Exiting."
	rm -rf ${WORKDIR}
	exit 1
    fi
done

ifOutOctets=1.3.6.1.2.1.2.2.1.16
for idx in $(cat ${WORKDIR}/ifIndexList)
do
    ${SNMPGET} -OQ -Ov -v2c -c ${community} ${targetip} ${ifOutOctets}.${idx} >> ${WORKDIR}/ifOutOctets
    if [ $? -ne 0 ]; then
	PERROR "Could not poll ifOutOctets for ${idx}. Exiting."
	rm -rf ${WORKDIR}
	exit 1
    fi
done

echo -n "${EPOCH}"
awk '{printf "\t%s", $0}' ${WORKDIR}/ifInOctets
awk '{printf "\t%s", $0}' ${WORKDIR}/ifOutOctets
echo

rm -rf ${WORKDIR}

# bottom of file
