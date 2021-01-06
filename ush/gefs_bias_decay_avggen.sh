#########################################################
# Script: gefs_bias_decay_avggen.sh
# Abstract: this script generate bias estimation 3 hourly 
# Author: Bo Cui ---- Oct. 2016
#########################################################

set -x

cd $DATA/dir_decay

export pgm=gefs_bias_gen

###############################################
# start mean bias calculation for 3hr lead time
###############################################

for nens in $memberlist; do

  for nfhrs in $hourlist; do

    nfile=0
    if [ -s namin_${nfhrs}_${nens}_biasgen ]; then
      rm namin_${nfhrs}_${nens}_biasgen
    fi

    rem=`echo "${nfhrs}%6" | bc`

    if [ $rem -eq 0 ]; then
      echo "$nfhrs is even number, no need to calculate Bias"
    else
      echo "$nfhrs is odd number, need to calculate Bias"

      echo " &namens" >>namin_${nfhrs}_${nens}_biasgen

      nfhrsm03=`expr $nfhrs - 03`
      nfhrsp03=`expr $nfhrs + 03`

      iskip=1
      file=ge${nens}.t${cyc}z.pgrb2a.0p50_mef${nfhrsm03}
      if [ $nfhrsm03 -lt 100 -a $nfhrsm03 -gt 10 ];then
        file=ge${nens}.t${cyc}z.pgrb2a.0p50_mef0${nfhrsm03}
      elif [ $nfhrsm03 -lt 10 -a $nfhrsm03 -gt 0 ];then
        file=ge${nens}.t${cyc}z.pgrb2a.0p50_mef00${nfhrsm03}
      elif [ $nfhrsm03 -eq 0 ];then
        file=ge${nens}.t${cyc}z.pgrb2a.0p50_mef000
      fi
      if [ -s $file ]; then
        iskip=0
        (( nfile = nfile + 1 ))
      fi
      echo " cfipg(1)='${file}'," >>namin_${nfhrs}_${nens}_biasgen
      echo " iskip(1)=${iskip},"  >>namin_${nfhrs}_${nens}_biasgen

      iskip=1
      file=ge${nens}.t${cyc}z.pgrb2a.0p50_mef${nfhrsp03}
      if [ $nfhrsp03 -lt 100 -a $nfhrsp03 -gt 10 ];then
        file=ge${nens}.t${cyc}z.pgrb2a.0p50_mef0${nfhrsp03}
      elif [ $nfhrsp03 -lt 10 -a $nfhrsp03 -gt 0 ];then
        file=ge${nens}.t${cyc}z.pgrb2a.0p50_mef00${nfhrsp03}
      elif [ $nfhrsp03 -eq 0 ];then
        file=ge${nens}.t${cyc}z.pgrb2a.0p50_mef000
      fi
      if [ -s $file ]; then
        iskip=0
        (( nfile = nfile + 1 ))
      fi
      echo " cfipg(2)='${file}'," >>namin_${nfhrs}_${nens}_biasgen
      echo " iskip(2)=${iskip},"  >>namin_${nfhrs}_${nens}_biasgen
      echo " nfiles=$nfile,"      >>namin_${nfhrs}_${nens}_biasgen

      file=ge${nens}.t${cyc}z.pgrb2a.0p50_mef${nfhrs}
      echo " cfopg1='${file}',"   >>namin_${nfhrs}_${nens}_biasgen
      echo " /" >>namin_${nfhrs}_${nens}_biasgen
    fi

  done

  if [ -s poescript_bias_${nens} ]; then
    rm poescript_bias_${nens}
  fi

  for nfhrs in $hourlist; do
    rem=`echo "${nfhrs}%6" | bc`
    if [ $rem -eq 0 ]; then
      file=ge${nens}.t${cyc}z.pgrb2a.0p50_mef${nfhrs}
      echo "echo $nfhrs " is even number, no need to calculate Bias " " >> poescript_bias_${nens}
    else
      echo "$EXECgefs/${pgm} <namin_${nfhrs}_${nens}_biasgen > $pgmout.${nfhrs}.${nens}" >> poescript_bias_${nens}
    fi
  done

  if [ -s poescript_bias_${nens} ]; then
    chmod +x poescript_bias_${nens}
    startmsg
    $APRUN poescript_bias_${nens}
#   $APRUN_32 poescript_bias_${nens}
    export err=$?; err_chk
    wait
  fi
done

set +x
echo " "
echo "Leaving sub script gefs_bias_decay_avggen.sh"
echo " "
set -x

