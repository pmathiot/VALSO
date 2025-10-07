#!/bin/bash

if [ $# -eq 0 ] ; then echo 'need a [KEYWORD] (will be inserted inside the output name) and a list of id [RUNIDS RUNID ...] (definition of line style need to be done in RUNID.db)'; exit; fi

. ~/.bashrc
. PARAM/param_arch.bash
load_python

KEY=${1}
FREQ=${2}
RUNIDS=${@:3}

echo 'plot SO SST time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f SO_sst*${FREQ}*.nc -var '(mean_votemper|mean_thetao)' -title "SO sst [K]" -dir ${WRKPATH} -o ${KEY}_fig05 -obs OBS/SO_sst_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

echo 'plot 09 SIE time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -varf 'GLO*sie*m02*.nc' 'GLO*sie*m09*.nc' -var SExnsidc SExnsidc -sf 0.001 0.001 -title "SIE Antarctic m02 [1e6 km2]" "SIE Antarctic m09 [1e6 km2]" -dir ${WRKPATH} -o ${KEY}_fig08 -obs OBS/ANT_sie02_obs.txt OBS/ANT_sie09_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# trim figure
convert ${KEY}_fig05.png -crop 1240x1040+0+0 tmp05.png
convert ${KEY}_fig08.png -crop 1240x1040+0+0 tmp08.png
convert FIGURES/box_VALGLO.png -trim -bordercolor White -border 40 tmp09.png
convert FIGURES/box_VALGLO.png -trim -bordercolor White -border 40 tmp09.png
convert legend.png             -trim -bordercolor White -border 20 tmp10.png
convert runidname.png          -trim -bordercolor White -border 20 tmp11.png

# compose the image
convert \( tmp05.png tmp08.png tmp09.png +append \) \
           tmp10.png tmp11.png -append -trim -bordercolor White -border 40 $KEY.png

# save plot
mv ${KEY}_*.png FIGURES/.
mv ${KEY}_*.txt FIGURES/.
mv tmp10.png FIGURES/${KEY}_legend.png
mv tmp11.png FIGURES/${KEY}_runidname.png

# clean
rm tmp??.png

# display
#display -resize 30% $KEY.png
