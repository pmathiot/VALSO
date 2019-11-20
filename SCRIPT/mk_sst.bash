#!/bin/bash
#SBATCH --mem=1G
#SBATCH --time=10
#SBATCH --ntasks=1

if [[ $# -ne 4 ]]; then echo 'mk_sst.bash [CONFIG (eORCA12, eORCA025 ...)] [RUNID (mi-aa000)] [TAG (19991201_20061201_ANN)] [FREQ (1y)]'; exit 1 ; fi

CONFIG=$1
RUNID=$2
TAG=$3
FREQ=$4
GRID='T'

# load path and mask
. param.bash
. ${SCRPATH}/common.bash

cd $DATPATH/

# name
RUN_NAME=${RUNID#*-}

# download data if needed
#${SCRPATH}/get_data.bash $RUNID $FREQ $TAG grid-${GRID}

# check presence of input file
FILE=nemo_${RUN_NAME}o_${FREQ}_${TAG}_grid-${GRID}.nc
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_sst.bash $@ (see SLURM/${CONFIG}/${RUNID}/sst_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# make sst
FILEOUT=SO_sst_nemo_${RUN_NAME}o_${FREQ}_${TAG}_grid-${GRID}.nc
if [ $CONFIG == 'eORCA025' ] ; then $CDFPATH/cdfmean -f $FILE -v '|thetao|votemper|' -surf -w 0 0 384 510 1 1 -p T -minmax -o tmp_$FILEOUT ; fi

# mv output file
if [[ $? -eq 0 ]]; then 
   mv tmp_$FILEOUT $FILEOUT
else 
   echo "error when running cdfmean; exit"; echo "E R R O R in : ./mk_sst.bash $@ (see SLURM/${CONFIG}/${RUNID}/sst_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi

FILEOUT=NWC_sst_nemo_${RUN_NAME}o_${FREQ}_${TAG}_grid-${GRID}.nc
if [ $CONFIG == 'eORCA025' ] ; then $CDFPATH/cdfmean -f $FILE -surf -v '|thetao|votemper|' -w 950 1020 870 940 1 1 -p T -minmax -o tmp_$FILEOUT ; fi

#mv output file
if [[ $? -eq 0 ]]; then 
   mv tmp_$FILEOUT $FILEOUT
else 
   echo "error when running cdfmean; exit"; echo "E R R O R in : ./mk_sst.bash $@ (see SLURM/${CONFIG}/${RUNID}/sst_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi
