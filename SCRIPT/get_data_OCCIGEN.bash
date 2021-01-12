#!/bin/bash -l
#SBATCH --mem=500
#SBATCH --time=60
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --constraint HSW24

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
if   [ $FREQ == '5d' ]; then echo '';
elif [ $FREQ == '1m' ]; then echo '';
elif [ $FREQ == '1y' ]; then echo '';
else echo '$FREQ frequency is not supported'; exit 1
fi

# flexibility for old-style filenames:
#GRID=$(echo $GRID | sed 's/-/[-_]/g')

FILE_LST=`ls ${STOPATH}/${FREQ}/*/${NEMOPREFIX}_${GRID}.nc`;

for MFILE in `echo ${FILE_LST}`; do
   FILE=`basname $MFILE`
   if [ -f $FILE ]; then 
      TIME=`ncdump -h $FILE | grep UNLIMITED | sed -e 's/(//' | awk '{print $6}'`
      if [[ $TIME -eq 0 ]]; then echo " $FILE is corrupted "; rm $FILE; fi
   fi
   if [ ! -f $FILE ]; then
      echo "downloading file ${FILE}"
      cp $MFILE .
   fi
done
