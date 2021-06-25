#!/bin/bash
#SBATCH --mem=10G
#SBATCH --time=10
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --constraint BDW28

if [[ $# -ne 4 ]]; then echo 'mk_eke.bash [CONFIG (eORCA12, eORCA025 ...)] [RUNID (mi-aa000)] [TAG (19991201_20061201_ANN)] [FREQ (1y)]'; exit 1 ; fi

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

GRID=$GRIDU ; FILEU=`get_nemofilename`
GRID=$GRIDV ; FILEV=`get_nemofilename`
GRID=$GRIDT ; FILET=`get_nemofilename`
if [ ! -f $FILEV ] ; then echo "$FILEV is missing; exit"; echo "E R R O R in : ./mk_eke.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_eke_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi
if [ ! -f $FILEU ] ; then echo "$FILEU is missing; exit"; echo "E R R O R in : ./mk_eke.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_eke_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi
if [ ! -f $FILET ] ; then echo "$FILET is missing; exit"; echo "E R R O R in : ./mk_eke.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_eke_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# make eke
FILEOUT=${CONFIG}-${RUNID}_${FREQ}_${TAG}_eke.nc
$CDFPATH/cdfeke -u $FILEU -u2 $FILEU -v $FILEV -v2 $FILEV -t $FILET -nc4 -mke -o tmp_$FILEOUT

# mv output file
if [[ $? -eq 0 ]]; then 
   mv tmp_$FILEOUT $FILEOUT
else 
   echo "error when running cdfeke; exit"; echo "E R R O R in : ./mk_eke.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_eke_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi
