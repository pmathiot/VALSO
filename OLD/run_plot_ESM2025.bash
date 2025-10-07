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
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *ACC*${FREQ}*.nc -var vtrp -sf -1 -title "c) ACC transport (Sv)" -dir ${WRKPATH} -o "${KEY}_fig03" -obs OBS/ACC_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# ROSS GYRE
echo 'plot Ross Gyre time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *RG*${FREQ}*psi.nc -var max_sobarstf -title "b) Ross Gyre (Sv)" -dir ${WRKPATH} -o ${KEY}_fig02 -sf 0.000001 -obs OBS/RG_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi
# WED GYRE
echo 'plot Weddell Gyre time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *WG*${FREQ}*psi.nc -var max_sobarstf -title "a) Weddell Gyre (Sv)" -dir ${WRKPATH} -o ${KEY}_fig01 -sf 0.000001 -obs OBS/WG_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean S WROSS
echo 'plot mean bot S (WROSS) time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *WROSS*so*${FREQ}*T.nc -var '(mean_sosbs|mean_vosaline)' -title "e) Mean bot. sal. WROSS (g/kg)" -dir ${WRKPATH} -o ${KEY}_fig04 -obs OBS/WROSS_botS_mean_obs.txt
# mean S WWED
if [[ $? -ne 0 ]]; then exit 42; fi
echo 'plot mean bot S (WWED) time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *WWED*so*${FREQ}*T.nc   -var '(mean_sosbs|mean_vosaline)' -title "d) Mean bot. sal. WWED  (g/kg)" -dir ${WRKPATH} -o ${KEY}_fig05  -obs OBS/WWED_botS_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean T FRIS
echo 'plot mean bot T (FRIS) time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f FRIS*thetao*${FREQ}*T.nc   -var '(mean_sosbt_tmask)' -title "f) Mean bot. temp. FRIS (C)"   -dir ${WRKPATH} -o ${KEY}_fig06  -obs OBS/FRIS_botT_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean T ROSS
echo 'plot mean bot T (ROSS) time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ROSS*thetao*${FREQ}*T.nc   -var '(mean_sosbt_tmask)' -title "g) Mean bot. temp. ROSS(C)"   -dir ${WRKPATH} -o ${KEY}_fig07   -obs OBS/ROSS_botT_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean T AMU
echo 'plot mean bot T (AMUS) time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f AMUS*thetao*${FREQ}*T.nc   -var '(mean_sosbt_tmask)' -title "h) Mean bot. temp. AMU (C)"   -dir ${WRKPATH} -o ${KEY}_fig08   -obs OBS/AMUS_botT_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# PIG
echo 'plot total FRIS time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ISF_ALL*${FREQ}*.nc -var '(isfmelt_FRIS)' -title "i) FRIS total melt (Gt/y)" -sf -1.0 -dir ${WRKPATH} -o ${KEY}_fig09 -obs OBS/FRIS_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# ROSS
echo 'plot total ROSS melt time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ISF_ALL*${FREQ}*.nc -var '(isfmelt_ROSS)' -title "j) ROSS total melt (Gt/y)"  -sf -1.0 -dir ${WRKPATH} -o ${KEY}_fig10  -obs OBS/ROSS_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# PINE
echo 'plot total PINE G melt time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ISF_ALL*${FREQ}*.nc -var '(isfmelt_PINE)' -title "k) PIG total melt (Gt/y)"   -sf -1.0 -dir ${WRKPATH} -o ${KEY}_fig11  -obs OBS/PINE_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi


# crop figure (rm legend)
for figid in {01..11}; do
   convert ${KEY}_fig${figid}.png -crop 1240x1040+0+0 tmp${figid}.png
done

# trim figure (remove white area)
convert FIGURES/box_ESM2025.png -trim -bordercolor White -border 40 tmp12.png
convert legend.png      -trim -bordercolor White -border 20 tmp13.png
convert runidname.png   -trim -bordercolor White -border 20 tmp14.png

# compose the image
convert \( tmp01.png tmp02.png tmp03.png +append \) \
        \( tmp04.png tmp05.png tmp12.png +append \) \
        \( tmp06.png tmp07.png tmp08.png +append \) \
        \( tmp09.png tmp10.png tmp11.png +append \) \
           tmp13.png tmp14.png -append -trim -bordercolor White -border 40 $KEY.png

# save figure
mv ${KEY}_*.png FIGURES/.
mv ${KEY}_*.txt FIGURES/.
mv tmp13.png FIGURES/${KEY}_legend.png
mv tmp14.png FIGURES/${KEY}_runidname.png

# clean
rm tmp??.png

#display
#display -resize 30% $KEY.png
