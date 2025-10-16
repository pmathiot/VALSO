#!/bin/bash

# where mask are stored (name of mesh mask in SCRIPT/common.bash)
MSKPATH=${CCCSCRATCHDIR}/DATA_MONITORING/${RUNID}/NEMO
MSHMSK=${RUNID}_mesh_mask.nc
SUBMSK=${RUNID}_subbasins.nc
ISFMSK=${RUNID}_isfmsk.nc
ISFLST=${RUNID}_isflst.txt

# STORE DIR (where data are)
STOPATH=${CCCSCRATCHDIR}/DATA_MONITORING/${RUNID}/NEMO
SIMPATH=${STOPATH}/

# CFG path, ie where processing is done (CONFIG and RUNID are fill by script)
DATPATH=${WRKPATH}/${CONFIG}-${RUNID}/
if [ ! -d $DATPATH ]; then mkdir -p $DATPATH ; fi

# NEMO output format (update it for your need)
#       for TAG see get_tag below
#ECM71-ico-LR-pi-01_18500101_18591231_1Y_grid_V.nc
NEMOFILE=${RUNID}_${TAG}_${FREQ^^}_${GRID}.nc

# grid (update it for your need)
GRIDT=grid_T ; GRIDU=grid_U ; GRIDV=grid_V ; GRIDI=icemod ; GRIDflx=grid_T

# frequency of the monthly file (1m means 1 file per month, 1y means 1 file per 12 month)
FREQF='1m'

# get NEMO FILE
get_nemofilename() {
  echo ${RUNID}_${TAG}_${FREQ^^}_${GRID}.nc
}

# get TAG
get_tag() {
  FREQ=$1 ; YYYY=$2 ; MM=$3 ; DD=$4
  if [ $FREQ == '10y' ]; then
     echo y${YYYY}
  elif [ $FREQ == '5y' ]; then
     echo y${YYYY}
  elif [ $FREQ == '1y' ]; then
     echo ${YYYY}
  elif [ $FREQ == '1m' ]; then
     echo ${YYYY}${MM}
  else
     echo y${YYYY}m${MM}d${DD}
  fi
}

# CDFTOOLS
# is the run vvl ?
VVL=-vvl
# do we need to run cdfbottom ?
BOT=0
