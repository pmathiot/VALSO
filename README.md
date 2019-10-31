# VALSO

================================================
## Purpose
* This toolbox only assess the order 0 of the southern ocean circulation :
   * ACC
   * Weddell gyre
   * Ross gyre strength
   * Salinity of HSSW 
   * Intrusion of CDW in Amundsen sea
   * Intrusion of CDW on East Ross shelf

* Compare simulated metrics with what is called a good-enough simulation (this range is estimated from expert judgements not observation dataset)

================================================
## Limitation
* only work for eORCA025 at the moment (section and box hard coded by index not lat/lon):
   * need to find a better management of the box indexes (need CDFTOOLS modification or an other step to build the mask on the fily with lat/lon boxes)
   * need a better management of section (need CDFTOOLS modification)
* plot should not be used for publication as it is (std and mean value of observation should be corrected if you want to do so)

================================================
## Installation
Simplest instalation (maybe not the most optimal)
* copy the VALIDATION_SO directory
* clean what is inside SLURM directory (optional)
* clean ERROR.txt file (optional)
* edit param.bash to fit your setup/need
   * mesh mask location with mesh mask name
   * location of the toolbox
   * where to store the data
   * where are your CDFTOOLS version 4.0 

* these module are required : 
   gcc/8.1.0 
   mpi/mpich/3.2.1/gnu/8.1.0 
   hdf5/1.8.20/gnu/8.1.0 
   netcdf/4.6.1/gnu/8.1.0
   scitools/production-os41-1

================================================
## Usage
* define your style for each simulation (file style.db)
* ./run_all.bash [CONFIG] [YEARB] [YEARE] [RUNID list] 
    example : ./run_all.bash eORCA025 1976 1977 u-ar685 u-bj000 u-bn477 u-az867 u-am916 u-ba470

Once this is done and if no error or minor error 
(ie for example we ask from 2000 to 2020 
but some simulation only span between 2010 and 2020. In this case no data will be built for the period 2000 2009 but erro will show up)

you can now build the plot:
* ./run_plot.bash [KEY] [RUNID list]
   example : ./run_plot.bash cpl_and_forced u-am916 u-az867 u-ba470 u-ar685 u-bj000 u-bn477

===============================================
## Output
* figure [KEY].png

Other output : 
* bsf, bottom T, bottom S, september mld netcdf file for each year in your DATPATH directory.
* all individual time series are saved in FIGURES along with the txt file describing the exact command line done to build it

