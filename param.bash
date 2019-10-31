#!/bin/bash

ulimit -s unlimited

MSKPATH=${DATADIR}/MESH_MASK/
CDFPATH=/project/nemo/TOOLS/CDFTOOLS/CDFTOOLS_4.0_master/bin/
EXEPATH=${HOME}/VALSO/
SCRPATH=${HOME}/VALSO/SCRIPT/

module load gcc/8.1.0 mpi/mpich/3.2.1/gnu/8.1.0 hdf5/1.8.20/gnu/8.1.0 netcdf/4.6.1/gnu/8.1.0