#!/bin/bash
#SBATCH --mem=10G
#SBATCH --time=30
#SBATCH --ntasks=1

if [[ $# -ne 4 ]]; then echo 'mk_mxl.bash [CONFIG (eORCA12, eORCA025 ...)] [RUNID (mi-aa000)] [TAG (19991201_20061201_ANN)] [FREQ (1y)]'; exit 1 ; fi

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
${SCRPATH}/get_data.bash $RUNID $FREQ $TAG grid-${GRID}

# check presence of input file
FILE=nemo_${RUN_NAME}o_${FREQ}_${TAG}_grid-${GRID}.nc
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_mxl.bash $@ (see SLURM/${CONFIG}/${RUNID}/mxl_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# make mxl
FILEOUT=WMXL_nemo_${RUN_NAME}o_${FREQ}_${TAG}_grid-${GRID}.nc
if [ $CONFIG == 'eORCA025' ] ; then $CDFPATH/cdfmean -f $FILE -v '|somxzint1|sokaraml|' -p T -w 1025 1300 325 380 0 0 -minmax -o tmp_$FILEOUT ; fi

# mv output file
if [[ $? -eq 0 ]]; then 
   mv tmp_$FILEOUT $FILEOUT
else 
   echo "error when running cdfmxl; exit"; echo "E R R O R in : ./mk_mxl.bash $@ (see SLURM/${CONFIG}/${RUNID}/mxl_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi
#
