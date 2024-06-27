#!/bin/bash

if [ $# -eq 0 ] ; then echo 'need a [KEYWORD] (will be inserted inside the output name) [FREQ] (1y) and a list of id [RUNIDS RUNID ...] (definition of line style need to be done in RUNID.db)'; exit; fi

. ~/.bashrc

KEY=${1}
FREQ=${2}
RUNIDS=${@:3}
echo $KEY  $FREQ $RUNIDS

#./run_plot_VALUSR.bash VALUSR_$KEY $FREQ $RUNIDS
./run_plot_VALGLO.bash VALGLO_$KEY $FREQ $RUNIDS
#./run_plot_VALSO.bash  VALSO_$KEY  $FREQ $RUNIDS
#./run_plot_VALSI.bash  VALSI_$KEY  $FREQ $RUNIDS
#./run_plot_VALAMU.bash VALAMU_$KEY $FREQ $RUNIDS
