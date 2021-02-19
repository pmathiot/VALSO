#!/bin/bash
#SBATCH --mem=1G
#SBATCH --time=10
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --constraint HSW24

if [[ $# -ne 4 ]]; then echo 'mk_icb.bash [CONFIG (eORCA12, eORCA025 ...)] [RUNID (mi-aa000)] [TAG (19991201_20061201_ANN)] [FREQ (1y)]'; exit 1 ; fi

CONFIG=$1
RUNID=$2
TAG=$3
FREQ=$4
VAR='|berg_melt|'
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
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_icb.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_icb_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

FILEOUT=${CONFIG}-${RUNID}_${FREQ}_${TAG}_icb-${GRID}.nc
set -x
# SH
$CDFPATH/cdfmean -f $FILE -v $VAR -p T -surf -o SH_$FILEOUT -B mask_bassin_SH.nc tmask
if [ $? -ne 0 ] ; then echo "error when running cdficb (SH)"; echo "E R R O R in : ./mk_icb.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_icb_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# NH
$CDFPATH/cdfmean -f $FILE -v $VAR -p T -surf -o NH_$FILEOUT -B mask_bassin_NH.nc tmask
if [ $? -ne 0 ] ; then echo "error when running cdficb (NH)"; echo "E R R O R in : ./mk_icb.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_icb_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi
