#!/bin/bash -l
#SBATCH --mem=500
#SBATCH --time=20
#SBATCH --ntasks=1

CONFIG=$1
RUNID=$2
FREQ=$3
TAG=$4
GRID=$5

. param.bash
. ${SCRPATH}/common.bash

cd ${DATPATH}

FILTER=${EXEPATH}/FILTERS/filter_${GRID}

# get data
if   [ $FREQ == '5d' ]; then CRUM_FREQ=ond;
elif [ $FREQ == '1m' ]; then CRUM_FREQ=onm;
elif [ $FREQ == '1s' ]; then CRUM_FREQ=ons;
elif [ $FREQ == '1y' ]; then CRUM_FREQ=ony;
else echo '$FREQ frequency is not supported'; exit 1
fi

if   [ $FREQ == '5d' ]; then FILE_LST=`moo ls moose:/crum/$RUNID/${CRUM_FREQ}.nc.file/*o_${FREQ}_${GRID}_${TAG}.nc`
else FILE_LST=`moo ls moose:/crum/$RUNID/${CRUM_FREQ}.nc.file/*o_${FREQ}_${TAG}_${GRID}.nc`;
fi

for MFILE in `echo ${FILE_LST}`; do
   FILE=${MFILE#*${CRUM_FREQ}.nc.file/}
   if [ -f $FILE ]; then 
      TIME=`ncdump -h $FILE | grep UNLIMITED | sed -e 's/(//' | awk '{print $6}'`
#      SIZEMASS=`moo ls -l $MFILE | awk '{ print $5}'`
#      SIZESYST=`    ls -l $FILE  | awk '{ print $5}'`
#      if [[ $SIZEMASS -ne $SIZESYST ]]; then echo " $FILE is corrupted "; rm $FILE; fi
      if [[ $TIME -eq 0 ]]; then echo " $FILE is corrupted "; rm $FILE; fi
   fi
   if [ ! -f $FILE ]; then
      echo "downloading file ${FILE}"
      moo filter $FILTER $MFILE .
   fi
done
