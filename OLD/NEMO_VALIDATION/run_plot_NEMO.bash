#!/bin/bash

if [ $# -eq 0 ] ; then echo 'need a [DIR] [KEYWORD] (will be inserted inside the output name) and a list of id [RUNIDS RUNID ...] (definition of line style need to be done in RUNID.db)'; exit; fi

DIR=${1}
KEY=${2}
RUNIDS=${@:3}

PATH_SCRIPT=./
######################################################################
# build all the plots
######################################################################
python ${PATH_SCRIPT}/plot_time_series.py -noshow -runid $RUNIDS -f O2L3P_*_1m_19000101_*1231_monitoring_ice_????02-*.nc -var SH_icevolu -sf 1 -title "Antarctic sea ice volume (m02) [1e3 km3]" -dir ${DIR} -o fig01
python ${PATH_SCRIPT}/plot_time_series.py -noshow -runid $RUNIDS -f O2L3P_*_1m_19000101_*1231_monitoring_ice_????09-*.nc -var SH_icevolu -sf 1 -title "Antarctic sea ice volume (m09) [1e3 km3]" -dir ${DIR} -o fig02
python ${PATH_SCRIPT}/plot_time_series.py -noshow -runid $RUNIDS -f O2L3P_*_1m_19000101_*1231_monitoring_ice_????02-*.nc -var SH_iceextt -sf 1 -title "Antarctic sea ice extent (m02) [1e6 km2]" -dir ${DIR} -o fig03
python ${PATH_SCRIPT}/plot_time_series.py -noshow -runid $RUNIDS -f O2L3P_*_1m_19000101_*1231_monitoring_ice_????09-*.nc -var SH_iceextt -sf 1 -title "Antarctic sea ice extent (m09) [1e6 km2]" -dir ${DIR} -o fig04

python ${PATH_SCRIPT}/plot_time_series.py -noshow -runid $RUNIDS -f O2L3P_*_1m_19000101_*1231_monitoring_ice_????02-*.nc -var NH_icevolu -sf 1 -title "Arctic sea ice volume (m02) [1e3 km3]" -dir ${DIR} -o fig05
python ${PATH_SCRIPT}/plot_time_series.py -noshow -runid $RUNIDS -f O2L3P_*_1m_19000101_*1231_monitoring_ice_????09-*.nc -var NH_icevolu -sf 1 -title "Arctic sea ice volume (m09) [1e3 km3]" -dir ${DIR} -o fig06
python ${PATH_SCRIPT}/plot_time_series.py -noshow -runid $RUNIDS -f O2L3P_*_1m_19000101_*1231_monitoring_ice_????02-*.nc -var NH_iceextt -sf 1 -title "Arctic sea ice extent (m02) [1e6 km2]" -dir ${DIR} -o fig07
python ${PATH_SCRIPT}/plot_time_series.py -noshow -runid $RUNIDS -f O2L3P_*_1m_19000101_*1231_monitoring_ice_????09-*.nc -var NH_iceextt -sf 1 -title "Arctic sea ice extent (m09) [1e6 km2]" -dir ${DIR} -o fig08

python ${PATH_SCRIPT}/plot_time_series.py -noshow -runid $RUNIDS -f O2L3P_*_1y_19000101_*1231_monitoring_oce_*.nc -var volo        -sf 1.e-9 -title "global volume [1e9 m3]" -dir ${DIR} -o fig20
python ${PATH_SCRIPT}/plot_time_series.py -noshow -runid $RUNIDS -f O2L3P_*_1y_19000101_*1231_monitoring_oce_*.nc -var soga        -sf 1     -title "global salinity [g/kg]" -dir ${DIR} -o fig21
python ${PATH_SCRIPT}/plot_time_series.py -noshow -runid $RUNIDS -f O2L3P_*_1y_19000101_*1231_monitoring_oce_*.nc -var bigthetaoga -sf 1     -title "global temperature [C]" -dir ${DIR} -o fig22
python ${PATH_SCRIPT}/plot_time_series.py -noshow -runid $RUNIDS -f O2L3P_*_1y_19000101_*1231_monitoring_oce_*.nc -var tosga       -sf 1     -title "global sst" -dir ${DIR} -o fig23

#####################################################
# Set the figure layout
#####################################################

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

# clean
rm tmp??.png fig??.png fig??.txt
rm legend.png runidname.png

# display
display -resize 30% $KEY.png
