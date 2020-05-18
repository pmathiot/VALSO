#!/bin/bash

ulimit -s unlimited

# where mask are stored (name of mesh mask in SCRIPT/common.bash)
MSKPATH=${DATADIR}/MESH_MASK/
# where cdftools are stored
#CDFPATH=/project/nemo/TOOLS/CDFTOOLS/CDFTOOLS_4.0_master/bin/
CDFPATH=/home/h05/pmathiot/TOOLS/CDFTOOLS_4.0/bin
# toolbox location
EXEPATH=${HOME}/VALSO/
# SCRIPT location
SCRPATH=${HOME}/VALSO/SCRIPT/
# DATA path (CONFIG and RUNID are fill by script
DATPATH=${SCRATCH}/ACC/$CONFIG/$RUNID/           

# diagnostics bundle
RUNVALSO=1
RUNVALGLO=0
RUNALL=0
# custom
runACC=0
runMLD=0
runBSF=1
runBOT=0
runMOC=0
runMHT=0
runSIE=0
runSST=0
runQHF=0
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
#else
#   echo 'need to define what you want in param.bash; exit 42'
#   exit 42
fi
   
module load gcc/8.1.0 mpi/mpich/3.2.1/gnu/8.1.0 hdf5/1.8.20/gnu/8.1.0 netcdf/4.6.1/gnu/8.1.0
