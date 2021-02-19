#!/bin/bash
#SBATCH --mem=1G
#SBATCH --time=10
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --constraint HSW24

if [[ $# -ne 4 ]]; then echo 'mk_hfds.bash [CONFIG (eORCA12, eORCA025 ...)] [RUNID (mi-aa000)] [TAG (19991201_20061201_ANN)] [FREQ (1y)]'; exit 1 ; fi

CONFIG=$1
RUNID=$2
TAG=$3
FREQ=$4
# load path and mask
. param.bash

# load config param
. PARAM/param_${CONFIG}.bash

# make links
. ${SCRPATH}/common.bash

cd $DATPATH/

# check presence of input file
GRID=$GRIDflx
FILE=`get_nemofilename`
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_hfds.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_hfds_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# make mxl
FILEOUT=GLO_hfds_${CONFIG}-${RUNID}_${FREQ}_${TAG}_grid-${GRID}.nc
set -x
pwd
$CDFPATH/cdfmean -f $FILE -v '|sohefldo|hfds|' -surf -p T -o $FILEOUT 

# mv output file
if [[ $? -ne 0 ]]; then 
   echo "error when running cdfmean; exit"; echo "E R R O R in : ./mk_hfds.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_hfds_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi
#
