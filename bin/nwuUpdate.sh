#!/bin/bash
#
# nwuUpdate.sh
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

mkdir ${WORKDIR}
if [ $? -ne 0 ]; then
    PERROR "Could not create ${WORKDIR}. Exiting."
    exit 1
fi

device=$1

${NWUBASE}/bin/nwuCollect.sh ${device} > ${WORKDIR}/${device}
if [ $? -ne 0 ]; then
    PERROR "${NWUBASE}/bin/nwuCollect.sh failed. Exiting."
    rm -rf ${WORKDIR}
    exit 1
fi

histFile=${LIVEDATADIR}/${device}

if [ ! -f ${histFile} ]; then
    cat ${WORKDIR}/${device} > ${histFile}
else
    updated=0
    while [ ${updated} -eq 0 ]
    do
	flock -w .01 ${histFile} cat ${WORKDIR}/${device} >> ${histFile}
	if [ $? -eq 0 ]; then
	    updated=1
	fi
    done
fi

rm -rf ${WORKDIR}

# bottom of file
