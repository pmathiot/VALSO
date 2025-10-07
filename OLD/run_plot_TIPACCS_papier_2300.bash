#!/bin/bash

if [ $# -eq 0 ] ; then echo 'need a [KEYWORD] (will be inserted inside the output name), [FREQ] (1y or 1m) and a list of id [RUNIDS RUNID ...] (definition of line style need to be done in RUNID.db)'; exit; fi

KEY=${1}
FREQ=${2}
RUNIDS=${@:3}

. ~/.bashrc
. PARAM/param_arch.bash
load_python

# ACC
# Drake
echo 'plot ACC time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *ACC*${FREQ}*.nc -var vtrp -sf -1 -title "c) ACC transport (Sv)" -dir ${WRKPATH} -o "${KEY}_fig03"
if [[ $? -ne 0 ]]; then exit 42; fi

# ROSS GYRE
echo 'plot Ross Gyre time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *RG*${FREQ}*psi.nc -var max_sobarstf -title "b) Ross Gyre (Sv)" -dir ${WRKPATH} -o ${KEY}_fig02 -sf 0.000001
if [[ $? -ne 0 ]]; then exit 42; fi

# WED GYRE
echo 'plot Weddell Gyre time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *WG*${FREQ}*psi.nc -var max_sobarstf -title "a) Weddell Gyre (Sv)" -dir ${WRKPATH} -o ${KEY}_fig01 -sf 0.000001
if [[ $? -ne 0 ]]; then exit 42; fi

# crop figure (rm legend)
for figid in {01..03}; do
   convert ${KEY}_fig${figid}.png -crop 1240x1040+0+0 tmp${figid}.png
done

# trim figure (remove white area)
convert legend.png      -trim -bordercolor White -border 20 tmp04.png

# compose the image
convert \( tmp01.png tmp02.png tmp03.png +append \) \
           tmp04.png -append -trim -bordercolor White -border 40 fig07.png

# save figure
mv ${KEY}_*.png FIGURES/.
mv ${KEY}_*.txt FIGURES/.
mv tmp04.png FIGURES/${KEY}_legend.png

# clean
rm tmp??.png


# FRIS
echo 'plot total FRIS time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ISF_ALL*${FREQ}*.nc -var '(isfmelt_FRIS)' -title "a) FRIS total melt (Gt/y)" -sf -1.0 -dir ${WRKPATH} -o ${KEY}_fig06
if [[ $? -ne 0 ]]; then exit 42; fi

# ROSS
echo 'plot total ROSS melt time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ISF_ALL*${FREQ}*.nc -var '(isfmelt_ROSS)' -title "b) ROSS total melt (Gt/y)"  -sf -1.0 -dir ${WRKPATH} -o ${KEY}_fig07
if [[ $? -ne 0 ]]; then exit 42; fi

# PINE
echo 'plot total PINE G melt time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ISF_ALL*${FREQ}*.nc.PIGandTwaites -var '(isfmelt_PIGandTwaites)' -title "c) PIG and Twaites total melt (Gt/y)"   -sf -1.0 -dir ${WRKPATH} -o ${KEY}_fig08
if [[ $? -ne 0 ]]; then exit 42; fi


# crop figure (rm legend)
for figid in {06..08}; do
   convert ${KEY}_fig${figid}.png -crop 1240x1040+0+0 tmp${figid}.png
done

# trim figure (remove white area)
convert legend.png      -trim -bordercolor White -border 20 tmp13.png

# compose the image
convert  \( tmp06.png tmp07.png tmp08.png +append \) \
           tmp13.png -append -trim -bordercolor White -border 40 fig13.png

# save figure
mv ${KEY}_*.png FIGURES/.
mv ${KEY}_*.txt FIGURES/.
mv tmp13.png FIGURES/${KEY}_legend.png

# clean
rm tmp??.png
