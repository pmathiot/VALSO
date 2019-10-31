#!/bin/bash
#SBATCH --mem=10G
#SBATCH --time=30
#SBATCH --ntasks=1

if [[ $# -ne 4 ]]; then echo 'mk_bot.bash [CONFIG (eORCA12, eORCA025 ...)] [RUNID (mi-aa000)] [TAG (19991201_20061201_ANN)] [FREQ (1y)]'; exit 1 ; fi

CONFIG=$1
RUNID=$2
TAG=$3
FREQ=$4

GRID=T

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
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/bot_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# make bot
FILEOUT=nemo_${RUN_NAME}o_${FREQ}_${TAG}_bottom-${GRID}.nc
$CDFPATH/cdfbottom -f $FILE -nc4 -o tmp_$FILEOUT

# mv output file
if [[ $? -eq 0 ]]; then 
   mv tmp_$FILEOUT $FILEOUT
else 
   echo "error when running cdfbottom; exit"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/bot_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ;
   exit 1
fi

# Amundsen avg (CDW)
if [ $CONFIG == 'eORCA025' ] ; then $CDFPATH/cdfmean -f $FILEOUT -v '|thetao|votemper|' -p T -var -w 710 741 202 266 0 0 -minmax -o AMU_thetao_$FILEOUT ; fi
if [ $? -ne 0 ] ; then echo "error when running cdfmean (AMU)"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/bot_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# WRoss avg (bottom water)
if [ $CONFIG == 'eORCA025' ] ; then $CDFPATH/cdfmean -f $FILEOUT -v '|so|vosaline|'     -p T -var -w 347 404 150 233 0 0 -minmax -o WROSS_so_$FILEOUT     ; fi
if [ $? -ne 0 ] ; then echo "error when running cdfmean (WROS)"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/bot_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# ERoss avg (CDW)
if [ $CONFIG == 'eORCA025' ] ; then $CDFPATH/cdfmean -f $FILEOUT -v '|thetao|votemper|' -p T -var -w 448 519 152 180 0 0 -minmax -o EROSS_thetao_$FILEOUT ; fi
if [ $? -ne 0 ] ; then echo "error when running cdfmean (EROSS)"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/bot_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# Weddell Avg (bottom water)
if [ $CONFIG == 'eORCA025' ] ; then $CDFPATH/cdfmean -f $FILEOUT -v '|so|vosaline|'     -p T -var -w 891 938 204 258 0 0 -minmax -o WED_so_$FILEOUT     ; fi
if [ $? -ne 0 ] ; then echo "error when running cdfmean (WWED)"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/bot_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi
#
