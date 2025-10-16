#!/bin/bash

if [ $# -eq 0 ] ; then echo 'need a [KEYWORD] (will be inserted inside the output name), [FREQ] (1y or 1m) and a list of id [RUNIDS RUNID ...] (definition of line style need to be done in RUNID.db)'; exit; fi

KEY=${1}
FREQ=${2}
RUNIDS=${@:3}

. ~/.bashrc
. PARAM/param_arch.bash
load_python
# CDW
# mean T EROSS
echo 'plot mean bot T (EWED) time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *EWED*thetao*${FREQ}*T.nc -var '(mean_sosbt|mean_votemper)' -title "a) Mean bottom temp. EWED (C)" -dir ${WRKPATH} -o ${KEY}_fig01 -obs OBS/EWED_botT_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean T AMU
echo 'plot mean bot T (AMU) time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *AMU_*thetao*${FREQ}*T.nc   -var '(mean_sosbt|mean_votemper)' -title "b) Mean bottom temp. AMU (C)"   -dir ${WRKPATH} -o ${KEY}_fig02   -obs OBS/AMU_botT_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# FRIS
echo 'plot total FRIS time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ISF_ALL*${FREQ}*.nc -var '(isfmelt_FRIS)' -title "c) FRIS total melt (Gt/y)" -sf -1.0 -dir ${WRKPATH} -o ${KEY}_fig03 -obs OBS/FRIS_obs_paolo2023.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# PINE
echo 'plot total PINE G melt time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ISF_ALL*${FREQ}*.nc -var '(isfmelt_PINE)' -title "d) PIG total melt (Gt/y)"   -sf -1.0 -dir ${WRKPATH} -o ${KEY}_fig04 -obs OBS/PINE_obs_paolo2023.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# crop figure (rm legend)
for figid in {01..04}; do
   convert ${KEY}_fig${figid}.png -crop 1240x1040+0+0 tmp${figid}.png
done

# trim figure (remove white area)
convert legend.png      -trim -bordercolor White -border 20 tmp13.png

# compose the image
convert  \( tmp01.png tmp02.png +append \) \
	 \( tmp03.png tmp04.png +append \) \
           tmp13.png -append -trim -bordercolor White -border 40 ${KEY}.png

# save figure
mv ${KEY}_*.png FIGURES/.
mv ${KEY}_*.txt FIGURES/.
mv tmp13.png FIGURES/${KEY}_legend.png

# clean
rm tmp??.png

#display
#display -resize 30% $KEY.png
