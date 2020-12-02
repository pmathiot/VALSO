#!/bin/bash
#SBATCH --mem=1G
#SBATCH --time=10
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --constraint HSW24

if [[ $# -ne 4 ]]; then echo 'mk_bot.bash [CONFIG (eORCA12, eORCA025 ...)] [RUNID (mi-aa000)] [TAG (19991201_20061201_ANN)] [FREQ (1y)]'; exit 1 ; fi

CONFIG=$1
RUNID=$2
TAG=$3
FREQ=$4
TBOTvar='|sosbt|'
SBOTvar='|sosbs|'
# load path and mask
. param.bash
. ${SCRPATH}/common.bash

cd $DATPATH/

# check presence of input file
GRID=$GRIDT
FILE=`get_nemofilename`
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_bot_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

FILEOUT=${CONFIG}-${RUNID}_${FREQ}_${TAG}_bottom-${GRID}.nc

# Amundsen avg (CDW)
ijbox=$($CDFPATH/cdffindij -c mesh.nc -p T -w -109.640 -102.230  -75.800  -71.660 | tail -2 | head -1)
set -x
$CDFPATH/cdfmean -f $FILE -v $TBOTvar -p T -var -w ${ijbox} 0 0 -minmax -o AMU_thetao_$FILEOUT 
if [ $? -ne 0 ] ; then echo "error when running cdfmean (AMU)"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_bot_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# WRoss avg (bottom water)
ijbox=$($CDFPATH/cdffindij -c mesh.nc -p T -w 157.100  173.333  -78.130  -74.040 | tail -2 | head -1)
$CDFPATH/cdfmean -f $FILE -v $SBOTvar -p T -var -w ${ijbox} 0 0 -minmax -o WROSS_so_$FILEOUT 
if [ $? -ne 0 ] ; then echo "error when running cdfmean (WROS)"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_bot_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# ERoss avg (CDW)
ijbox=$($CDFPATH/cdffindij -c mesh.nc -p T -w -176.790 -157.820  -78.870  -77.520 | tail -2 | head -1)
$CDFPATH/cdfmean -f $FILE -v $TBOTvar -p T -var -w ${ijbox} 0 0 -minmax -o EROSS_thetao_$FILEOUT 
if [ $? -ne 0 ] ; then echo "error when running cdfmean (EROSS)"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_bot_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# Weddell Avg (bottom water)
ijbox=$($CDFPATH/cdffindij -c mesh.nc -p T -w -65.130  -53.020  -75.950  -72.340 | tail -2 | head -1)
$CDFPATH/cdfmean -f $FILE -v $SBOTvar  -p T -var -w ${ijbox} 0 0 -minmax -o WED_so_$FILEOUT 
if [ $? -ne 0 ] ; then echo "error when running cdfmean (WWED)"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_bot_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# FRIS shelf
$CDFPATH/cdfmean -f $FILE -v $TBOTvar  -p T -var -minmax -o FRIS_thetao_$FILEOUT -B msk_WED_shelf.nc tmask
if [ $? -ne 0 ] ; then echo "error when running cdfmean (FRIS)"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_bot_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# ROSS shelf
$CDFPATH/cdfmean -f $FILE -v $TBOTvar  -p T -var -minmax -o ROSS_thetao_$FILEOUT -B msk_ROSS_shelf.nc tmask
if [ $? -ne 0 ] ; then echo "error when running cdfmean (ROSS)"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_bot_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# AMU  shelf
$CDFPATH/cdfmean -f $FILE -v $TBOTvar  -p T -var -minmax -o AMUS_thetao_$FILEOUT -B msk_AMU_shelf.nc tmask
if [ $? -ne 0 ] ; then echo "error when running cdfmean (AMUS)"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_bot_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi
