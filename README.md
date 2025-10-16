# VALSO

## Purpose
* This toolbox only assess the order 0 of the southern ocean circulation :
   * ACC
   * Weddell gyre
   * Ross gyre strength
   * Salinity of HSSW 
   * Intrusion of CDW in Amundsen sea
   * Intrusion of CDW on East Ross shelf
   * AMOC
   * MHT
   * NWC sst
   * ISF melt
   * NH/SH sea ice extent (summer and winter)

* Compare simulated metrics with what is called a good-enough simulation (this range is estimated from expert judgements not observation dataset)

![Alt text](FIGURES/example.png?raw=true "Example of the VALSO output")

## Installation
Simplest instalation (maybe not the most optimal)
* install the CDFTOOLS at v3.0.2-355-g66ce3da :
```
   git clone https://github.com/pmathiot/CDFTOOLS_4.0_ISF.git
```
* ckeckout the VALSO directory
```
   git clone https://github.com/pmathiot/VALSO.git
```
* edit PARAM/param_yourcomputer.bash to fit your setup/need
   * path of the toolbox (`$EXEPATH`)
   * path of the processing directory (`$WRKPATH`) 
   * path of the CDFTOOLS version 4.0 bin drectory (`$CDFPATH`)
   * create a link toward PARAM/param_arch.bash
* edit `PARAM/param_CONFIG.bash` (`$CONFIG`, `$RUNID`, `$FREQ`, `$GRID` are automatically filled during the run, so they can be used in param_CONFIG.bash). Rename the file with the correct CONFIG name (eORCA025.L121 in my case).
   * path of the mask file (`$MSKPATH`) and the corresponding mask name (`$MSHMSK`, `$SUBMSK`, `$ISFMSK` and `$ISFLST`)
   * path of storage location (`$STOPATH`)
   * template for the file name (`$NEMOFILE`)
   * edit `get_nemofile` function to match your output name.
   * edit `get_tag` function to match your output name.

* the module required are the one used to compiled the CDFTOOLS and nco 

### Compute the time series
* define your style for each simulation (file style.db)
* `./run_all.bash [CONFIG] [YEARB] [YEARE] [FREQ (1y or 1m)] [RUNID list]` as example : 
```
./run_all.bash eORCA025.L121 1976 1977 1y OPM006 OPM007
```
will proceed the year 1976 to 1977 for runid OPM006 and OPM007 of configuration eORCA025.L121

Once this is done and if no error or minor errors 
(ie for example we ask from 2000 to 2020 
but some simulation only span between 2010 and 2020. In this case no data will be built for the period 2000 2009 but error will show up)

### Build the plots

See `README_run_plot.md`
