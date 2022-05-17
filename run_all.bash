#!/bin/bash

. param.bash

#=============================================================================================================================
#                         FUNCTIONS 
#=============================================================================================================================

compute_obs_diags() {
   [[ $runMEAN == 1 ]] && sbatch mk_mean $CONFIG $TAG $RUNID $FREQ OBSTS > /dev/null 2>&1
}

compute_diags() {
   # define tags
   TAG=$(get_tag ${FREQ} ${YEAR} ${MONTH} 01)

   # get data (retreive_data function are defined in this script)
   [[ $runACC == 1 || $runBSF == 1 || $runMOC == 1 || $runMHT == 1 || $runEKE == 1 ]]      && mooVyid=$(retreive_data $CONFIG $RUNID $FREQ $TAG $GRIDV  )
   [[ $runACC == 1 || $runBSF == 1 || $runMOC == 1 || $runEKE == 1 ]]                      && mooUyid=$(retreive_data $CONFIG $RUNID $FREQ $TAG $GRIDU  )
   if [ $GRIDflx != $GRIDT ] ; then 
      [[ $runBOT == 1 || $runSST == 1 || $runISF == 1 || $runMEAN == 1 || $runEKE == 1 ]]  && mooTyid=$(retreive_data $CONFIG $RUNID $FREQ $TAG $GRIDT  )
      [[ $runQHF == 1 || $runICB == 1 || $runISF == 1 ]]                                   && mooQyid=$(retreive_data $CONFIG $RUNID $FREQ $TAG $GRIDflx)
   else
      [[ $runBOT == 1 || $runSST == 1 || $runQHF == 1 || $runICB == 1 || $runISF == 1 || $runMEAN == 1 || $runEKE == 1 ]] && mooTyid=$(retreive_data $CONFIG $RUNID $FREQ $TAG $GRIDT  )
      mooQyid=$mooTyid
   fi

   # run cdftools
   [[ $runACC  == 1 ]] && runACCy00id=$(run_tool mk_trp  $CONFIG $TAG $RUNID $FREQ $mooVyid:$mooUyid)
   [[ $runBSF  == 1 ]] && runPSIy00id=$(run_tool mk_psi  $CONFIG $TAG $RUNID $FREQ $mooVyid:$mooUyid              )
   [[ $runBOT  == 1 ]] && runBOTy00id=$(run_tool mk_bot  $CONFIG $TAG $RUNID $FREQ $mooTyid:$moomskid             )
   [[ $runMOC  == 1 ]] && runMOCy00id=$(run_tool mk_moc  $CONFIG $TAG $RUNID $FREQ $mooVyid:$mooTyid              )
   [[ $runMHT  == 1 ]] && runMHTy00id=$(run_tool mk_mht  $CONFIG $TAG $RUNID $FREQ $mooVyid:$mooVyid              )
   [[ $runQHF  == 1 ]] && runHFDy00id=$(run_tool mk_hfds $CONFIG $TAG $RUNID $FREQ $mooQyid                       )
   [[ $runISF  == 1 ]] && runISFy00id=$(run_tool mk_isf  $CONFIG $TAG $RUNID $FREQ $mooQyid:$mooTyid              )
   [[ $runICB  == 1 ]] && runICBy00id=$(run_tool mk_icb  $CONFIG $TAG $RUNID $FREQ $mooQyid:$moomskid             )
   [[ $runSST  == 1 ]] && runSSTy00id=$(run_tool mk_sst  $CONFIG $TAG $RUNID $FREQ $mooTyid                       )
   [[ $runMEAN == 1 ]] && runAVGy00id=$(run_tool mk_mean $CONFIG $TAG $RUNID $FREQ $mooTyid                       )
   [[ $runEKE  == 1 ]] && runEKEy00id=$(run_tool mk_eke  $CONFIG $TAG $RUNID $FREQ $mooTyid:$mooUyid:$mooVyid     )

   JOBID=`echo "$JOBID $mooVyid $mooUyid $mooTyid $mooQyid $mooTyid $mooQyid"`
   JOBID=`echo "$JOBID $runACCy00id $runPSIy00id $runBOTy00id $runMOCy00id $runMHTy00id $runHFDy00id $runISFy00id $runICBy00id $runSSTy00id $runAVGy00id $runEKEy00id"`
}

compute_onlymonthly_diags() {
   # define tag      
   TAG09=$(get_tag 1m ${YEAR} 09 01)
   TAG02=$(get_tag 1m ${YEAR} 02 01)
   TAG03=$(get_tag 1m ${YEAR} 03 01)

   # get data (retreive_data function are defined in this script)
   if   [[ $FREQF == 1y ]]  ; then   # tag02=tag09=tag03
      [[ $runMLD == 1 ]]                                              && mooT09mid=$(retreive_data $CONFIG $RUNID 1m $TAG02 $GRIDT)
      [[ $runSIE == 1 ]]                                              && mooI02mid=$(retreive_data $CONFIG $RUNID 1m $TAG02 $GRIDI)
      mooT03mid=$mooT09mid
      mooI03mid=$mooI02mid
      mooI09mid=$mooI02mid

      [[ $runMLD == 1 ]] && runmxly00id=$(run_tool mk_mxl  $CONFIG $TAG09 $RUNID 1m    $mooT09mid:$moomskid )
      [[ $runSIE == 1 ]] && runsiey00id=$(run_tool mk_sie  $CONFIG $TAG09 $RUNID 1m    $mooI09mid:$moomskid )

      JOBID=`echo "$JOBID $mooT09mid $mooI02mid $mooT03mid $mooI03mid $mooI09mid $runmxly00id $runsiey00id"`

   elif [[ $FREQF == 1m ]]  ; then
      [[ $runMLD == 1 ]]                                                 && mooT09mid=$(retreive_data $CONFIG $RUNID 1m $TAG09 $GRIDT)
      [[ $runMLD == 1 ]]                                                 && mooT03mid=$(retreive_data $CONFIG $RUNID 1m $TAG03 $GRIDT)
      [[ $runSIE == 1 ]]                                                 && mooI09mid=$(retreive_data $CONFIG $RUNID 1m $TAG09 $GRIDI)
      [[ $runSIE == 1 ]]                                                 && mooI02mid=$(retreive_data $CONFIG $RUNID 1m $TAG02 $GRIDI)
      [[ $runSIE == 1 ]]                                                 && mooI03mid=$(retreive_data $CONFIG $RUNID 1m $TAG03 $GRIDI)

   # run cdftools
      [[ $runMLD == 1 ]] && runmxlm09id=$(run_tool mk_mxl  $CONFIG $TAG09 $RUNID 1m    $mooT09mid:$moomskid)
      [[ $runSIE == 1 ]] && runsiem09id=$(run_tool mk_sie  $CONFIG $TAG09 $RUNID 1m    $mooI09mid:$moomskid )
      [[ $runSIE == 1 ]] && runsiem02id=$(run_tool mk_sie  $CONFIG $TAG02 $RUNID 1m    $mooI02mid:$moomskid )
      [[ $runSIE == 1 ]] && runsiem03id=$(run_tool mk_sie  $CONFIG $TAG03 $RUNID 1m    $mooI03mid:$moomskid )

      JOBID=`echo "$JOBID $mooT09mid $mooT03mid $mooI09mid $mooI02mid $mooI03mid $runmxlm09id $runsiem09id $runsiem02id $runsiem03id"`

   fi

}

progress_bar() {
   sleep 5
   echo''
   njob=`echo $JOBID | wc -w`
   ijob=$njob
   eval "printf '|' ; printf '%0.s ' {0..100} ; printf '|\r' ;"
   while [[ $ijob -ne 0 ]] ; do
     ijob=`$JOBSTATcmd | grep 'SO_' | wc -l`
     icar=$(( ( (njob - ijob) * 100 ) / njob ))
     eval "printf '|' ; printf '%0.s=' {0..$icar} ; printf '\r' ; "
     sleep 1
   done
   eval "printf '|' ; printf '%0.s=' {0..100} ; printf '|\n' ;"
   echo ''
}
#=============================================================================================================================
if [ $# -le 4 ]; then echo 'run_all.sh [CONFIG] [YEARB] [YEARE] [FREQ] [RUNID list]'; exit 42; fi

CONFIG=$1
YEARB=$2
YEARE=$3
FREQ=$4
RUNIDS=${@:5}

. PARAM/param_arch.bash

# clean ERROR.txt file
if [ -f ERROR.txt ]; then rm ERROR.txt ; fi

# loop over years
echo ''
for RUNID in `echo $RUNIDS`; do

   . PARAM/param_${CONFIG}.bash

   # set up jobout directory file
   JOBOUT_PATH=${EXEPATH}/SLURM/${CONFIG}/${RUNID}
   if [ ! -d ${JOBOUT_PATH} ]; then mkdir -p ${JOBOUT_PATH} ; fi

   echo "$RUNID ..."

   njob=0
   LSTY=`eval echo {${YEARB}..${YEARE}}`
   LSTM=`eval echo {1..12}`

   [[ $runICB == 1 || $runBOT == 1 || $runSIE == 1 || $runMLD ]] && moomskid=$(build_mask $CONFIG $RUNID )

   [[ $runOBS == 1 ]] && compute_obs_diags

   MONTH=00
   for YEAR in `printf "%04d " $LSTY`; do

      if [[ $FREQ == 1y || $FREQ == 10y || $FREQ == 5y || $FREQF == 1y ]]  ; then
         compute_diags
      elif [[ $FREQ == 1m ]]                ; then
         for MONTH in `printf "%02d " $LSTM`; do
             compute_diags
         done
      fi

      compute_onlymonthly_diags
      
   done

   # print task bar
   progress_bar  
 
   # wait it is all done (probably useless because of the progress bar loop)
#   wait

   # retreive all job exit
   if [ -f log_status_$RUNID ]; then rm log_status_$RUNID ; fi
   echo "===========================" >> log_status_$RUNID
   echo "   for YEARS in $LSTY   " >> log_status_$RUNID
   echo "===========================" >> log_status_$RUNID
   for id in $JOBID; do
       sacct -j $id --format=jobid,jobname%40,state,exitcode | grep "$id " >> log_status_$RUNID
   done
   grep -v COMPLETED log_status_$RUNID
   echo 'DONE'

done # end runids
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

