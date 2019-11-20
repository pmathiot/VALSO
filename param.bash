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

module load gcc/8.1.0 mpi/mpich/3.2.1/gnu/8.1.0 hdf5/1.8.20/gnu/8.1.0 netcdf/4.6.1/gnu/8.1.0
