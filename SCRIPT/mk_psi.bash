#!/bin/bash
#SBATCH --mem=1G
#SBATCH --time=10
#SBATCH --ntasks=1

if [[ $# -ne 4 ]]; then echo 'mk_psi.bash [CONFIG (eORCA12, eORCA025 ...)] [RUNID (mi-aa000)] [TAG (19991201_20061201_ANN)] [FREQ (1y)]'; exit 1 ; fi

CONFIG=$1
RUNID=$2
TAG=$3
FREQ=$4

# load path and mask
. param.bash
. ${SCRPATH}/common.bash

cd $DATPATH/

# name
RUN_NAME=${RUNID#*-}

# download data if needed
${SCRPATH}/get_data.bash $RUNID $FREQ $TAG grid-V
${SCRPATH}/get_data.bash $RUNID $FREQ $TAG grid-U

# check presence of input file
FILEU=nemo_${RUN_NAME}o_${FREQ}_${TAG}_grid-U.nc
FILEV=nemo_${RUN_NAME}o_${FREQ}_${TAG}_grid-V.nc
if [ ! -f $FILEV ] ; then echo "$FILEV is missing; exit"; echo "E R R O R in : ./mk_psi.bash $@ (see SLURM/${CONFIG}/${RUNID}/psi_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi
if [ ! -f $FILEU ] ; then echo "$FILEU is missing; exit"; echo "E R R O R in : ./mk_psi.bash $@ (see SLURM/${CONFIG}/${RUNID}/psi_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# make psi
FILEOUT=nemo_${RUN_NAME}o_${FREQ}_${TAG}_psi.nc
$CDFPATH/cdfpsi -u $FILEU -v $FILEV -vvl -nc4 -ref 1 1 -o tmp_$FILEOUT

# mv output file
if [[ $? -eq 0 ]]; then 
   mv tmp_$FILEOUT $FILEOUT
else 
   echo "error when running cdfpsi; exit"; echo "E R R O R in : ./mk_psi.bash $@ (see SLURM/${CONFIG}/${RUNID}/psi_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi

# WG max
if [ $CONFIG == 'eORCA025' ] ; then $CDFPATH/cdfmean -f $FILEOUT -v sobarstf -p T -w 1025 1300 325 380 0 0 -minmax -o WG_$FILEOUT ; fi
if [ $? -ne 0 ] ; then echo "error when running cdfmean (WG)"; echo "E R R O R in : ./mk_psi.bash $@ (see SLURM/${CONFIG}/${RUNID}/psi_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# RG max
if [ $CONFIG == 'eORCA025' ] ; then $CDFPATH/cdfmean -f $FILEOUT -v sobarstf -p T -w 476 607 254 370 0 0 -minmax -o RG_$FILEOUT ; fi
if [ $? -ne 0 ] ; then echo "error when running cdfmean (RG)"; echo "E R R O R in : ./mk_psi.bash $@ (see SLURM/${CONFIG}/${RUNID}/psi_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi
