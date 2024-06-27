
Assumption
==========
- You already have all your scalar you want to plot as time series ready somewhere. I let you compute or output directly via xios the variable you want
- Conda is avalaible on your computer (much easier to set up the correct environement). You can create it via the yml file 
- image magic (`convert`)

Data location
=============
Data directory tree is very simple. Let's say you want to compare 2 simulations called `NEMO_v4.2.2` and `NEMO_v5.0`. 
In this case, you simply need to dump all the netcdf that contain the scalar or time series you want to plot in 2 different repo call `NEMO_v4.2.2` and `NEMO_v5.0` each in a master directory of your choice.
This directory can be anywhere on your computer.

```
DATA ----- O2IP_CLIM_NEMO422
             |
             --- O2IP_CLIM_NEMO5
```

Setup
=====
- 1: activate your python environement: `conda activate valso`
- 2: setup your line definition for python in `style.db`

```
(valso) [my_prompt]$ cat style.db 
 runid                   |     name      |   line   |   color        |
 O2IP_CLIM_NEMO5         | NEMO_v5       |   -      | sienna         |
 O2IP_CLIM_NEMO422       | NEMO_v422     |   -      | cornflowerblue |
```
   * `runid` is the simulation name
   * `name` meaningfull name for the plot legend
   * `line` and `color` the style used for the plot

Plotting tool
=============

The plotting script is based on the python script ``:
```
python ${PATH_SCRIPT}/plot_time_series.py -noshow -runid <list of runids> -f <input files list (wild card accepted like *toto*.nc)> -var <variable name> -sf <scale factor> -title "title [unit]" -dir <master directory (DATA)> -o <tmp figure name (fig01)
```

Once all the plot are build a page is build using image magic:

```
# trim figure
for file in fig??.png ; do
    convert $file -crop 1240x1040+0+0 tmp${file#fig}
done

convert legend.png     -trim -bordercolor White -border 20 tmp10.png
convert runidname.png  -trim -bordercolor White -border 20 tmp11.png

# compose the image
convert \( tmp01.png tmp02.png tmp03.png tmp04.png +append \) \
        \( tmp05.png tmp06.png tmp07.png tmp08.png +append \) \
        \( tmp20.png tmp21.png tmp22.png tmp23.png +append \) \
           tmp10.png tmp11.png -append -trim -bordercolor White -border 40 $KEY.png
```

So you can edit easily the script to match your need as long as the data are already available as scalar or time series with a record dimension to concatenate the data (time series out of XIOS already have the correct format).

Data example:
```
netcdf O2L3P_LONG_NEMO4.2.2_1y_19000101_19091231_monitoring_oce_1904-1904 {
dimensions:
	...
	time_dimension = UNLIMITED ; // (1 currently)
variables:
	double time_coordinate(time_counter) ;
		...
	float bgtemper(time_counter) ;
		bgtemper:coordinates = "time_coordinate" ;
		...
```

Output
======

![plot](./NEMO.png)
