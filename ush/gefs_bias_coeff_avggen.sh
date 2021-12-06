#!/bin/sh
######################################################################
# Script: gefs_bias_coeff_avggen.sh
# Abstract: this script generate coeff for 03hr, 09hr and etc forecast 
# Author: Bo Cui ---- Mar. 2017 First implementation
######################################################################

set -x
cd $DATA/dir_coeff

export pgm=gefs_bias_gen

####################################
# define exec variable, and hourlist
####################################

memlist="avg"

######################################################
# start mean combination coefficient for 3hr lead time
######################################################

for nens in $memlist; do

  for nfhrs in $hourlist; do

    nfile=0

    if [ -s namin_${nfhrs}_${nens}_rfbias ]; then
      rm namin_${nfhrs}_${nens}_rfbias
    fi

    rem=`echo "${nfhrs}%6" | bc`

    if [ $rem -eq 0 ]; then
      echo "$nfhrs is even number, no need to calculate reforecast bias"
    else
      echo "$nfhrs is odd number, need to calculate reforecast bias"

      echo " &namens" >>namin_${nfhrs}_${nens}_rfbias

      nfhrsm03=`expr $nfhrs - 03`
      nfhrsp03=`expr $nfhrs + 03`

      iskip=1
      file=ge${nens}.t${cyc}z.pgrb2a.0p50_coefff${nfhrsm03}
      if [ $nfhrsm03 -lt 100 -a $nfhrsm03 -gt 10 ];then
        file=ge${nens}.t${cyc}z.pgrb2a.0p50_coefff0${nfhrsm03}
      elif [ $nfhrsm03 -lt 10 -a $nfhrsm03 -gt 0 ];then
        file=ge${nens}.t${cyc}z.pgrb2a.0p50_coefff00${nfhrsm03}
      elif [ $nfhrsm03 -eq 0 ];then
        file=ge${nens}.t${cyc}z.pgrb2a.0p50_coefff000
      fi
      if [ -s $file ]; then
        iskip=0
        (( nfile = nfile + 1 ))
      fi
      echo " cfipg(1)='${file}'," >>namin_${nfhrs}_${nens}_rfbias
      echo " iskip(1)=${iskip},"  >>namin_${nfhrs}_${nens}_rfbias

      iskip=1
      file=ge${nens}.t${cyc}z.pgrb2a.0p50_coefff${nfhrsp03}
      if [ $nfhrsp03 -lt 100 -a $nfhrsp03 -gt 10 ];then
        file=ge${nens}.t${cyc}z.pgrb2a.0p50_coefff0${nfhrsp03}
      elif [ $nfhrsp03 -lt 10 -a $nfhrsp03 -gt 0 ];then
        file=ge${nens}.t${cyc}z.pgrb2a.0p50_coefff00${nfhrsp03}
      elif [ $nfhrsp03 -eq 0 ];then
        file=ge${nens}.t${cyc}z.pgrb2a.0p50_coefff000
      fi
      if [ -s $file ]; then
        iskip=0
        (( nfile = nfile + 1 ))
      fi
      echo " cfipg(2)='${file}'," >>namin_${nfhrs}_${nens}_rfbias
      echo " iskip(2)=${iskip},"  >>namin_${nfhrs}_${nens}_rfbias
      echo " nfiles=$nfile,"      >>namin_${nfhrs}_${nens}_rfbias

      file=ge${nens}.t${cyc}z.pgrb2a.0p50_coefff${nfhrs}
      echo " cfopg1='${file}',"   >>namin_${nfhrs}_${nens}_rfbias
      echo " /" >>namin_${nfhrs}_${nens}_rfbias
    fi

  done

  if [ -s poescript_coeff_${nens} ]; then
    rm poescript_coeff_${nens}
  fi

  for nfhrs in $hourlist; do
    rem=`echo "${nfhrs}%6" | bc`
    if [ $rem -eq 0 ]; then
      file=ge${nens}.t${cyc}z.pgrb2a.0p50_coefff${nfhrs}
      echo "$nfhrs is even number, no need to calculate reforecast bias"
    else
      echo "$EXECgefs/${pgm} <namin_${nfhrs}_${nens}_rfbias > $pgmout.coeff.${nfhrs}.${nens}" >> poescript_coeff_${nens}
    fi
  done

  if [ -s poescript_coeff_${nens} ]; then
    chmod +x poescript_coeff_${nens}
    startmsg
    $APRUN poescript_coeff_${nens}
    export err=$?; err_chk
    wait
  fi

done

set +x
echo " "
echo "Leaving sub script gefs_bias_coeff_avggen.sh"
echo " "
set -x

