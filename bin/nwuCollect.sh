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

ifHCInOctets=1.3.6.1.2.1.31.1.1.1.6
for idx in $(cat ${WORKDIR}/ifIndexList)
do
    ${SNMPGET} -OQ -Ov -v2c -c ${community} ${targetip} ${ifHCInOctets}.${idx} >> ${WORKDIR}/ifHCInOctets
    if [ $? -ne 0 ]; then
	PERROR "Could not poll ifHCInOctets for ${idx}. Exiting."
	rm -rf ${WORKDIR}
	exit 1
    fi
done

ifHCOutOctets=1.3.6.1.2.1.31.1.1.1.10
for idx in $(cat ${WORKDIR}/ifIndexList)
do
    ${SNMPGET} -OQ -Ov -v2c -c ${community} ${targetip} ${ifHCOutOctets}.${idx} >> ${WORKDIR}/ifHCOutOctets
    if [ $? -ne 0 ]; then
	PERROR "Could not poll ifHCOutOctets for ${idx}. Exiting."
	rm -rf ${WORKDIR}
	exit 1
    fi
done

echo -n "${EPOCH}"
awk '{printf "\t%s", $0}' ${WORKDIR}/ifHCInOctets
awk '{printf "\t%s", $0}' ${WORKDIR}/ifHCOutOctets
echo

rm -rf ${WORKDIR}

# bottom of file
