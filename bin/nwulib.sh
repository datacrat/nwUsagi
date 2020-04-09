#!/bin/bash
#
# nwulib.sh
#
# (c) 2020 datacrat

if [ -z "${NWUBASE}" ]; then
    NWUBASE=/var/lib/nwusagi
fi
SCRIPTNAME=$(basename $0)
EPOCH=$(date +%s)
PID=$$

PERROR () {
    echo "[${SCRIPTNAME}:${BASH_LINENO}] $1" >&2
}

CONFDIR=${NWUBASE}/conf
TMPDIR=${NWUBASE}/tmp
WORKDIR=${TMPDIR}/${SCRIPTNAME}_${EPOCH}_${PID}
DEVLISTFILE=${CONFDIR}/devices

if [ ! -f ${DEVLISTFILE} ]; then
    PERROR "${DEVLISTFILE} is not found. Exiting."
    exit 1
fi

DATADIR=${NWUBASE}/data
LIVEDATADIR=${DATADIR}/live

# bottom of file
