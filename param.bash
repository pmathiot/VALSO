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

#RUNVALSO=0
#RUNVALGLO=0
#RUNALL=1
#
#if [[ $RUNVALSO == 1 ]]; then
#   runACC=1 #acc  ts
#   runMLD=1 #mld  ts
#   runBSF=1 #gyre ts
#   runBOT=1 #bottom TS ts
#elif [[ $RUNVALGLO == 1 ]]; then
#   runAMOC=1
#   runAMHT=1
#   runSIE=1
#   runSST=1
#elif [[ $RUNALL == 1 ]]; then
#   runACC=1 #acc  ts
#   runMLD=1 #mld  ts
#   runBSF=1 #gyre ts
#   runBOT=1 #bottom TS ts
#   runAMOC=1
#   runAMHT=1
#   runSIE=1
#   runSST=1
#else
#   echo 'need to define what you want in param.bash; exit 42'
#   exit 42
#fi
   

module load gcc/8.1.0 mpi/mpich/3.2.1/gnu/8.1.0 hdf5/1.8.20/gnu/8.1.0 netcdf/4.6.1/gnu/8.1.0
