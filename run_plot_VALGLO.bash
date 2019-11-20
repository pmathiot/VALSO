#!/bin/bash

if [ $# -eq 0 ] ; then echo 'need a [KEYWORD] (will be inserted inside the figure title and output name) and a list of id [RUNIDS RUNID ...] (definition of line style need to be done in RUNID.db)'; exit; fi

module load scitools/production-os41-1

DATPATH=${SCRATCH}/ACC/eORCA025

KEY=${1}
RUNIDS=${@:2}

# ACC
# Drake
echo 'plot ACC time series'
python2.7 SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *ACC*1.nc -var vtrp -sf -1 -title "ACC transport (Sv) : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig01 -obs OBS/ACC_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig01.png -crop 1240x1040+0+0 tmp01.png

# AMOC
echo 'plot AMOC time series'
python2.7 SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f rapid_*moc.nc -var Total_max_amoc_rapid -title "Max AMOC 26.5N (Sv) : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig02 -obs OBS/AMOC_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig02.png -crop 1240x1040+0+0 tmp02.png

# MHT 
echo 'plot MHT  time series'
python2.7 SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *mht*_265.nc -var zomht_atl -title "AMHT 26.5N (PW) : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig03 -obs OBS/AMHT_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig03.png -crop 1240x1040+0+0 tmp03.png

# QNET
echo 'plot QNET  time series'
python2.7 SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f GLO_hfds*.nc -var '(mean_sohefldo|mean_hfds)' -title "Net downward heat flux (W/m2) : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig04 -obs OBS/QNET_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig04.png -crop 1240x1040+0+0 tmp04.png

# SO SST
echo 'plot SO SST time series'
python2.7 SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f SO_sst*.nc -var '(mean_votemper|mean_thetao)' -title "SO sst [K] : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig05 -obs OBS/SO_sst_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig05.png -crop 1240x1040+0+0 tmp05.png

# SO SST
echo 'plot SO SST time series'
python2.7 SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f NWC_sst*.nc -var '(mean_votemper|mean_thetao)' -title "NWC sst [K] : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig06 -obs OBS/NWC_sst_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig06.png -crop 1240x1040+0+0 tmp06.png

# ARC SIE
echo 'plot 02 SIE time series'
python2.7 SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f '*sie*0201*.nc' -var NExnsidc SExnsidc -sf 0.001 -title "SIE Arctic m02 [1e6 km2] : ${KEY}" "SIE Antarctic m02 [1e6 km2] : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig07 -obs OBS/ARC_sie02_obs.txt OBS/ANT_sie02_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig07.png -crop 1240x1040+0+0 tmp07.png

echo 'plot 09 SIE time series'
python2.7 SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f '*sie*0901*.nc' -var NExnsidc SExnsidc -sf 0.001 -title "SIE Arctic m09 [1e6 km2] : ${KEY}" "SIE Antarctic m09 [1e6 km2] : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig08 -obs OBS/ARC_sie09_obs.txt OBS/ANT_sie09_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig08.png -crop 1240x1040+0+0 tmp08.png

convert FIGURES/box_VALGLO.png -trim -bordercolor White -border 40 tmp09.png
convert FIGURES/box_VALGLO.png -trim -bordercolor White -border 40 tmp09.png
convert legend.png             -trim -bordercolor White -border 20 tmp10.png
convert runidname.png          -trim -bordercolor White -border 20 tmp11.png

convert tmp01.png tmp02.png tmp03.png +append top_plot.png
convert tmp04.png tmp05.png tmp09.png +append mid_plot.png
convert tmp06.png tmp07.png tmp08.png +append bot_plot.png
convert top_plot.png mid_plot.png bot_plot.png tmp10.png tmp11.png -append -trim -bordercolor White -border 40 $KEY.png

mv ${KEY}_*.png FIGURES/.
mv ${KEY}_*.txt FIGURES/.
mv tmp10.png FIGURES/${KEY}_legend.png
mv tmp11.png FIGURES/${KEY}_runidname.png

rm top_plot.png mid_plot.png bot_plot.png tmp??.png

display -resize 30% $KEY.png