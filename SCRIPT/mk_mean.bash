#!/bin/bash
#SBATCH --mem=4G
#SBATCH --time=20
#SBATCH --ntasks=4
#SBATCH --nodes=1
#SBATCH --constraint HSW24

export OMP_NUM_THREADS=8

write_err() {
   echo "error when running cdfmean; exit"; echo "E R R O R in : ./mk_mean.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_mean_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
}

if [[ $# -ne 4 ]]; then echo 'mk_mean.bash [CONFIG (eORCA12, eORCA025 ...)] [RUNID (mi-aa000)] [TAG (19991201_20061201_ANN)] [FREQ (1y)]'; exit 1 ; fi
set -x
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

GRID=$GRIDT
FILE=`get_nemofilename`
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_mean.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_mean_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

ZONE='AMUSill'
LLBOX='-106.972 -101.992  -72.189  -70.970'
VART='votemper' ; VARS='vosaline'
PRET='Tprof'    ; PRES='Sprof' 

IJBOX=$($CDFPATH/cdffindij -c mesh.nc -p T -w $LLBOX | tail -2 | head -1)
# compute profile T
FILEOUT=${ZONE}_${PRET}_${CONFIG}-${RUNID}_${FREQ}_${TAG}_${GRID}.nc
$CDFPATH/cdfmean -f $FILE -v $VART -p T -o $FILEOUT -vvl  -w $IJBOX 0 0
if [[ $? -ne 0 ]]; then write_err ; fi

FILEOUT=${ZONE}_${PRES}_${CONFIG}-${RUNID}_${FREQ}_${TAG}_${GRID}.nc
$CDFPATH/cdfmean -f $FILE -v $VARS -p T -o $FILEOUT -vvl  -w $IJBOX 0 0
if [[ $? -ne 0 ]]; then write_err ; fi

ZONE='GETZSill'
LLBOX='-119.460 -117.478  -72.514  -71.841'
VART='votemper' ; VARS='vosaline'
PRET='Tprof'    ; PRES='Sprof' 

IJBOX=$($CDFPATH/cdffindij -c mesh.nc -p T -w $LLBOX | tail -2 | head -1)
# compute profile T
FILEOUT=${ZONE}_${PRET}_${CONFIG}-${RUNID}_${FREQ}_${TAG}_${GRID}.nc
$CDFPATH/cdfmean -f $FILE -v $VART -p T -o $FILEOUT -vvl  -w $IJBOX 0 0
if [[ $? -ne 0 ]]; then write_err ; fi

FILEOUT=${ZONE}_${PRES}_${CONFIG}-${RUNID}_${FREQ}_${TAG}_${GRID}.nc
$CDFPATH/cdfmean -f $FILE -v $VARS -p T -o $FILEOUT -vvl  -w $IJBOX 0 0
if [[ $? -ne 0 ]]; then write_err ; fi

