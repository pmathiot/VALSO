#!/bin/bash
#SBATCH --mem=4G
#SBATCH --time=20
#SBATCH --ntasks=4
#SBATCH --nodes=1
#SBATCH --constraint HSW24

export OMP_NUM_THREADS=8

write_err() {
   echo "error when running cdfisf_diags; exit"; echo "E R R O R in : ./mk_isf.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_isf_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
}

if [[ $# -ne 4 ]]; then echo 'mk_isf.bash [CONFIG (eORCA12, eORCA025 ...)] [RUNID (mi-aa000)] [TAG (19991201_20061201_ANN)] [FREQ (1y)]'; exit 1 ; fi
set -x
CONFIG=$1
RUNID=$2
TAG=$3
FREQ=$4
VAR='|fwfisf|sowflisf_cav|'
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
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_isf.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_isf_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# compute melt
FILEOUT=ISF_ALL_${CONFIG}-${RUNID}_${FREQ}_${TAG}_${GRID}.nc
$CDFPATH/cdfisf_diags -f $FILE -v $VAR -mskf mskisf.nc -mskv mask_isf -l isflst.txt -o $FILEOUT
if [[ $? -ne 0 ]]; then write_err ; fi
#
GRID=$GRIDT
FILE=`get_nemofilename`
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_isf.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_isf_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

jtop=$($CDFPATH/cdffindij -c mesh.nc -p T -w 0 0 -60 -60 | tail -2 | head -1 | awk '{print $3}')
# compute profile T
FILEOUT=ISF_Tprof_${CONFIG}-${RUNID}_${FREQ}_${TAG}_${GRID}.nc
$CDFPATH/cdfmean -f $FILE -v votemper -p T -I mskisf.nc mask_isf_front isflst.txt -o $FILEOUT ${VVL}  -w 0 0 1 $jtop 0 0
if [[ $? -ne 0 ]]; then write_err ; fi

FILEOUT=ISF_Sprof_${CONFIG}-${RUNID}_${FREQ}_${TAG}_${GRID}.nc
$CDFPATH/cdfmean -f $FILE -v vosaline -p T -I mskisf.nc mask_isf_front isflst.txt -o $FILEOUT ${VVL}  -w 0 0 1 $jtop 0 0
if [[ $? -ne 0 ]]; then write_err ; fi

