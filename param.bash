#!/bin/bash

ulimit -s unlimited
module load python/3.5.3
module load nco/4.7.9-gcc-4.8.5-hdf5-1.8.18-openmpi-2.0.4
module load qt

# where mask are stored (name of mesh mask in SCRIPT/common.bash)
MSKPATH=${SCRATCHDIR}/DRAKKAR/${CONFIG}/${CONFIG}-${RUNID}-MSH/
MSHMSK=${CONFIG}-${RUNID}_mesh_mask.nc
SUBMSK=${CONFIG}-${RUNID}_subbassins.nc
ISFMSK=${CONFIG}-${RUNID}_mskisf.nc
ISFLST=${CONFIG}-${RUNID}_isflst.nc

# where cdftools are stored
#CDFPATH=/project/nemo/TOOLS/CDFTOOLS/CDFTOOLS_4.0_master/bin/
CDFPATH=${HOME}/GIT/CDFTOOLS_4.0_ISF/bin

# toolbox location (where the toolbox is installed)
EXEPATH=${HOME}/GIT/VALSO/

# SCRIPT location (where script are, no need to be changed)
SCRPATH=${EXEPATH}/SCRIPT/

# STORE DIR (where data are)
STOPATH=${SCRATCHDIR}/DRAKKAR/${CONFIG}/${CONFIG}-${RUNID}-S/

# WORK path (where all the processing will be done)
WRKPATH=${SCRATCHDIR}/VALSO/

# CFG path (CONFIG and RUNID are fill by script, no need to be changed)
DATPATH=${WRKPATH}/${CONFIG}-${RUNID}/           

# NEMO output format (update it for your need)
#       for TAG see get_tag below
NEMOFILE=${CONFIG}-${RUNID}_${TAG}.${FREQ}_${GRID}.nc

# grid (update it for your need)
GRIDT=gridT ; GRIDU=gridU ; GRIDV=gridV ; GRIDI=icemod ; GRIDflx=flxT

# get NEMO FILE
get_nemofilename() {
  echo ${CONFIG}-${RUNID}_${TAG}.${FREQ}_${GRID}.nc
}

# get TAG
get_tag() {
  FREQ=$1 ; YYYY=$2 ; MM=$3 ; DD=$4
  if [ $FREQ == '1y' ]; then
     echo y${YYYY}
  elif [ $FREQ == '1m' ]; then
     echo y${YYYY}m${MM}
  else
     echo y${YYYY}m${MM}d${DD}
  fi
}

# diagnostics bundle
RUNVALSO=0
RUNVALGLO=0
RUNVALSI=0
RUNALL=1
# custom
runACC=0
runMLD=0
runBSF=0
runBOT=0
runMOC=0
runMHT=0
runSIE=0
runSST=0
runQHF=0
runISF=0
runICB=0
#
if [[ $RUNALL == 1 || $RUNTEST == 1 ]]; then
   runACC=1 #acc  ts
   runMLD=1 #mld  ts
   runBSF=1 #gyre ts
   runBOT=1 #bottom TS ts
   runMOC=1
   runMHT=1
   runSIE=1
   runSST=1
   runQHF=1
   runISF=1
   runICB=1
elif [[ $RUNVALSO == 1 ]]; then
   runACC=1 #acc  ts
   runMLD=1 #mld  ts
   runBSF=1 #gyre ts
   runBOT=1 #bottom TS ts
elif [[ $RUNVALGLO == 1 ]]; then
   runMOC=1
   runMHT=1
   runSIE=1
   runSST=1
   runQHF=1
elif [[ $RUNVALSI == 1 ]]; then
   runISF=1
   runICB=1
   runBOT=1
fi
