#!/bin/bash

if [ $# -eq 0 ]; then echo 'run_all.sh [CONFIG] [YEARB] [YEARE] [RUNID list]'; exit 42; fi

CONFIG=$1
YEARB=$2
YEARE=$3
RUNIDS=${@:4}

. param.bash

# clean ERROR.txt file
if [ -f ERROR.txt ]; then rm ERROR.txt ; fi

# loop over years
njob=0
for RUNID in `echo $RUNIDS`; do

   # set up jobout directory file
   JOBOUT_PATH=${EXEPATH}/SLURM/${CONFIG}/${RUNID}
   if [ ! -d ${JOBOUT_PATH} ]; then mkdir -p ${JOBOUT_PATH} ; fi

   echo ''
   echo $RUNID
   echo ''
   for YEAR in `eval echo {${YEARB}..${YEARE}}`; do
      # define tags
      TAG=${YEAR}1201-$((YEAR+1))1201
      TAG09=${YEAR}0901-${YEAR}1001

      # get data 
      mooVyid=$(sbatch --job-name=moo_${YEAR}_V --output=${JOBOUT_PATH}/moo_${YEAR}_V   ${SCRPATH}/get_data.bash $CONFIG $RUNID 1y $TAG   grid-V | awk '{print $4}')  # for mk_trp and mk_psi
      mooUyid=$(sbatch --job-name=moo_${YEAR}_U --output=${JOBOUT_PATH}/moo_${YEAR}_U   ${SCRPATH}/get_data.bash $CONFIG $RUNID 1y $TAG   grid-U | awk '{print $4}')  # for mk_trp and mk_psi
      mooTyid=$(sbatch --job-name=moo_${YEAR}_T --output=${JOBOUT_PATH}/moo_${YEAR}_T   ${SCRPATH}/get_data.bash $CONFIG $RUNID 1y $TAG   grid-T | awk '{print $4}')  # for mk_bot.bash
      mooTmid=$(sbatch --job-name=moo_${YEAR}_T --output=${JOBOUT_PATH}/moo_${YEAR}_T09 ${SCRPATH}/get_data.bash $CONFIG $RUNID 1m $TAG09 grid-T | awk '{print $4}')  # for mk_mxl.bash

      sbatch --wait --dependency=afterany:$mooVyid:$mooUyid --job-name=SO_trp_${TAG}_${RUNID} --output=${JOBOUT_PATH}/trp_${TAG}.out ${SCRPATH}/mk_trp.bash $CONFIG $RUNID $TAG   1y > /dev/null 2>&1 &
      njob=$((njob+1))

      sbatch --wait --dependency=afterany:$mooVyid:$mooUyid --job-name=SO_psi_${TAG}_${RUNID} --output=${JOBOUT_PATH}/psi_${TAG}.out ${SCRPATH}/mk_psi.bash $CONFIG $RUNID $TAG   1y > /dev/null 2>&1 &
      njob=$((njob+1))
      
      sbatch --wait --dependency=afterany:$mooTyid          --job-name=SO_mxl_${TAG}_${RUNID} --output=${JOBOUT_PATH}/mxl_${TAG}.out ${SCRPATH}/mk_mxl.bash $CONFIG $RUNID $TAG09 1m > /dev/null 2>&1 &
      njob=$((njob+1))

      sbatch --wait --dependency=afterany:$mooTmid          --job-name=SO_bot_${TAG}_${RUNID} --output=${JOBOUT_PATH}/bot_${TAG}.out ${SCRPATH}/mk_bot.bash $CONFIG $RUNID $TAG   1y > /dev/null 2>&1 &
      njob=$((njob+1))
   done
done

# print task bar
sleep 4
echo''
ijob=$njob
eval "printf '|' ; printf '%0.s ' {0..100} ; printf '|\r' ;"
while [[ $ijob -ne 0 ]] ; do
  ijob=`squeue -u ${USER} | grep 'SO_' | wc -l` 
  icar=$(( ( (njob - ijob) * 100 ) / njob ))
  eval "printf '|' ; printf '%0.s=' {0..$icar} ; printf '\r' ; "
  sleep 1
done
eval "printf ' |' ; printf '%0.s=' {0..100} ; printf '|\n' ;"

# wait it is done
wait

# print out
sleep 1
ls > /dev/null 2>&1 # without this the following command sometimes failed (maybe it force to flush all the file on disk)
if [ -f ERROR.txt ]; then
   echo ''
   echo 'ERRORS are present :'
   cat ERROR.txt
   echo ''
   echo 'if error expected (as missing data because data coverage larger than run coverage), diagnostics will be missing for these cases.'
else
   echo ''
   echo "data processing for Southern Ocean validation toolbox is done for ${RUNIDS} between ${YEARB} and ${YEARE}"
fi
echo ''
echo "You can now run < ./run_plot.bash [KEY] [RUNIDS] > if no more files to process (other resolution, other periods ...)"
echo ''
echo "by default ./run_plot.bash will process all the file in the data directory, if you want some specific period, you need to tune the glob.glob pattern in the script"
echo ''

