#!/bin/bash

if [ $# -eq 0 ] ; then echo 'need a [KEYWORD] (will be inserted inside the figure title and output name) and a list of id [RUNIDS RUNID ...] (definition of line style need to be done in RUNID.db)'; exit; fi

module load scitools/production-os41-1

DATPATH=${SCRATCH}/ACC/eORCA025

KEY=${1}
RUNIDS=${@:2}

# ACC
# Drake
echo 'plot ACC time series'
python2.7 SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *ACC*1.nc -var vtrp -sf -1 -title "ACC transport (Sv) : ${KEY}" -dir ${DATPATH} -o "${KEY}_ACC" -obs OBS/ACC_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# GYRE
# ROSS GYRE
echo 'plot Ross Gyre time series'
python2.7 SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *RG*psi.nc -var max_sobarstf -title "Ross Gyre (Sv) : ${KEY}" -dir ${DATPATH} -o ${KEY}_RG -sf 0.000001 -obs OBS/RG_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi
# WED GYRE
echo 'plot Weddell Gyre time series'
python2.7 SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *WG*psi.nc -var max_sobarstf -title "Weddell Gyre (Sv) : ${KEY}" -dir ${DATPATH} -o ${KEY}_WG -sf 0.000001 -obs OBS/WG_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# HSSW
# mean S WROSS
echo 'plot mean bot S (WROSS) time series'
python2.7 SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *WROSS*so*T.nc -var '(mean_so|mean_vosaline)' -title "Mean bot. sal. WROSS (PSU) : ${KEY}" -dir ${DATPATH} -o ${KEY}_WROSS_mean_bot_so -obs OBS/WROSS_botS_mean_obs.txt
# mean S WWED
if [[ $? -ne 0 ]]; then exit 42; fi
echo 'plot mean bot S (WWED) time series'
python2.7 SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *WED*so*T.nc   -var '(mean_so|mean_vosaline)' -title "Mean bot. sal. WWED  (PSU) : ${KEY}" -dir ${DATPATH} -o ${KEY}_WWED_mean_bot_so  -obs OBS/WWED_botS_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# CDW
# mean T AMU
echo 'plot mean bot T (AMU) time series'
python2.7 SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *AMU*thetao*T.nc   -var '(mean_thetao|mean_votemper)' -title "Mean bot. temp. AMU (C) : ${KEY}"   -dir ${DATPATH} -o ${KEY}_AMU_mean_bot_thetao   -obs OBS/AMU_botT_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi
# mean T EROSS
echo 'plot mean bot T (EROSS) time series'
python2.7 SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *EROSS*thetao*T.nc -var '(mean_thetao|mean_votemper)' -title "Mean bot. temp. EROSS (C) : ${KEY}" -dir ${DATPATH} -o ${KEY}_EROSS_mean_bot_thetao -obs OBS/EROSS_botT_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# MLD
# max mld in WEDDELL GYRE
echo 'plot max mld in Weddell Gyre time series'
python2.7 SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *WMXL*1m*0901-*T.nc -var '(max_sokaraml|max_somxzint1)' -title "Max Kara mld WG (m) : ${KEY}" -dir ${DATPATH} -o ${KEY}_WG_max_karamld -obs OBS/WG_karamld_max_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

convert ${KEY}_ACC.png ${KEY}_WG.png ${KEY}_RG.png +append top_plot.png
convert ${KEY}_WWED_mean_bot_so.png ${KEY}_WROSS_mean_bot_so.png FIGURES/box.png +append mid_plot.png
convert ${KEY}_AMU_mean_bot_thetao.png ${KEY}_EROSS_mean_bot_thetao.png ${KEY}_WG_max_karamld.png +append bot_plot.png
convert top_plot.png mid_plot.png bot_plot.png -append $KEY.png

rm top_plot.png mid_plot.png bot_plot.png

mv ${KEY}_*.png FIGURES/.
mv ${KEY}_*.txt FIGURES/.

display -resize 30% $KEY.png
