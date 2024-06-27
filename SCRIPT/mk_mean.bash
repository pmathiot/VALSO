#!/bin/bash

export OMP_NUM_THREADS=8

write_err() {
   echo "error when running cdfmean; exit"; echo "E R R O R in : ./mk_mean.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_mean_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
}

compute_means_obs() {
   IJBOX=$($CDFPATH/cdffindij -c mesh.nc -p T -w $LLBOX | tail -2 | head -1)
   # compute profile T
   FILEOUT=${ZONE}_${PRET}_${CONFIG}-${RUNID}_${FREQ}_${TAG}_${GRID}.nc
   $CDFPATH/cdfmean -f $FILE -v $VART -p T -o $FILEOUT -w $IJBOX 0 0
   if [[ $? -ne 0 ]]; then write_err ; fi

   FILEOUT=${ZONE}_${PRES}_${CONFIG}-${RUNID}_${FREQ}_${TAG}_${GRID}.nc
   $CDFPATH/cdfmean -f $FILE -v $VARS -p T -o $FILEOUT -w $IJBOX 0 0
   if [[ $? -ne 0 ]]; then write_err ; fi
}


compute_means() {
   IJBOX=$($CDFPATH/cdffindij -c mesh.nc -p T -w $LLBOX | tail -2 | head -1)
   # compute profile T
   FILEOUT=${ZONE}_${PRET}_${CONFIG}-${RUNID}_${FREQ}_${TAG}_${GRID}.nc
   $CDFPATH/cdfmean -f $FILE -v $VART -p T -o $FILEOUT ${VVL} -w $IJBOX 0 0
   if [[ $? -ne 0 ]]; then write_err ; fi

   FILEOUT=${ZONE}_${PRES}_${CONFIG}-${RUNID}_${FREQ}_${TAG}_${GRID}.nc
   $CDFPATH/cdfmean -f $FILE -v $VARS -p T -o $FILEOUT ${VVL} -w $IJBOX 0 0
   if [[ $? -ne 0 ]]; then write_err ; fi
}

# inputs
CONFIG=<CONFIG>
RUNID=<RUNID>
TAG=<TAG>
FREQ=<FREQ>

if [[ $# -lt 5 ]] ; then lOBS=0; fi

# load path and mask
. param.bash

# load config param
. PARAM/param_${CONFIG}.bash

# make links
. ${SCRPATH}/common.bash

cd $DATPATH/

if [[ lOBS -eq 1 ]]; then
    . PARAM/param_obs.bash
    FILE=${OBSTS_DIR}/${OBSTS_FILE}
else  
    GRID=$GRIDT
    FILE=`get_nemofilename`
fi

if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_mean.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_mean_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

if [[ lOBS -eq 1 ]]; then
    VART=$OBST_VAR
    VARS=$OBSS_VAR  
    RUNID=${OBSTS_NAME}_${OBSTS_ATT}
    TAG=$OBSTS_TAG
    MEAN_SCRIPT=compute_means_obs
else  
    VART='|votemper|t_an|thetao|' ; VARS='|vosaline|s_an|so|'
    MEAN_SCRIPT=compute_means
fi

PRET='Tprof'    ; PRES='Sprof' 
ZONE='AMUSill'
LLBOX='-106.972 -101.992  -72.189  -70.970'
$MEAN_SCRIPT

ZONE='GETZSill'
LLBOX='-119.460 -117.478  -72.514  -71.841'
$MEAN_SCRIPT

ZONE='AMUopen'
LLBOX='-130 -86 -70 -65'
$MEAN_SCRIPT

ZONE='ROSSgyre'
LLBOX='-168.500 -135.750 -72.650 -61.600'
$MEAN_SCRIPT

ZONE='WEDgyre'
LLBOX='-20.0 20.0 -66.500 -60.400'
$MEAN_SCRIPT

ZONE='WROSS'
LLBOX='157.100  173.333  -78.130  -74.040'
$MEAN_SCRIPT

ZONE='WWED'
LLBOX='-65.130  -53.020  -75.950  -72.340'
$MEAN_SCRIPT

ZONE='EROSS'
LLBOX='-176.790 -157.820  -78.870  -77.520'
$MEAN_SCRIPT

ZONE='EWED'
LLBOX='-45.647  -32.253  -78.632  -76.899'
$MEAN_SCRIPT

ZONE='AMU'
LLBOX='-109.640 -102.230  -75.800  -71.660'
$MEAN_SCRIPT
