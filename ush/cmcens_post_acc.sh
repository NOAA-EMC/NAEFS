#!/bin/sh
################################################################################
# Script: cmcens_post_acc.sh
# Abstract: this script generate CMC preciptation/flux variables 3 and 6 hourly 
# Author: Bo Cui ---- Feb. 2017
################################################################################

set -x

cd $DATA

pgm=cmcens_post_acc   

##############################################
# Begin Processing Members, Forecast Lead Time
##############################################

for nens in $memberlist; do

  cmcmem=`echo $nens | cut -c2-3`

  for nfhrs in $hourlist; do

    nfile=0
    if [ -s namin_${nfhrs}_${nens}_acc ]; then
      rm namin_${nfhrs}_${nens}_acc
    fi

    rem=`echo "${nfhrs}%6" | bc`

    if [ $rem -eq 0 ]; then
      echo "$nfhrs is even number, CMC ens post-process inter hr is 6"
      interhr=6
      nfhrsm06=`expr $nfhrs - 06`
    else
      echo "$nfhrs is odd number, CMC ens post-process inter hr is 3"
      interhr=3
      nfhrsm06=`expr $nfhrs - 03`
    fi

    echo " &namens" >>namin_${nfhrs}_${nens}_acc

    iskip=1
    file=$COMIN/${PDY}${cyc}_CMC_naefs_hr_latlon0p5x0p5_P${nfhrsm06}_0${cmcmem}.grib2
    if [ $nfhrsm06 -lt 100 -a $nfhrsm06 -gt 10 ];then
      file=$COMIN/${PDY}${cyc}_CMC_naefs_hr_latlon0p5x0p5_P0${nfhrsm06}_0${cmcmem}.grib2
    elif [ $nfhrsm06 -lt 10 -a $nfhrsm06 -gt 0 ];then
      file=$COMIN/${PDY}${cyc}_CMC_naefs_hr_latlon0p5x0p5_P00${nfhrsm06}_0${cmcmem}.grib2
    elif [ $nfhrsm06 -eq 0 ];then
      file=$COMIN/${PDY}${cyc}_CMC_naefs_hr_latlon0p5x0p5_P000_0${cmcmem}.grib2
    fi
    if [ -s $file ]; then
      iskip=0
      (( nfile = nfile + 1 ))
    fi
    echo " cfipg(1)='${file}'," >>namin_${nfhrs}_${nens}_acc
    echo " iskip(1)=${iskip},"  >>namin_${nfhrs}_${nens}_acc

    iskip=1
    file=$COMIN/${PDY}${cyc}_CMC_naefs_hr_latlon0p5x0p5_P${nfhrs}_0${cmcmem}.grib2
    if [ -s $file ]; then
      iskip=0
      (( nfile = nfile + 1 ))
    fi
    echo " cfipg(2)='${file}'," >>namin_${nfhrs}_${nens}_acc
    echo " iskip(2)=${iskip},"  >>namin_${nfhrs}_${nens}_acc
    echo " nfiles=$nfile,"      >>namin_${nfhrs}_${nens}_acc

    file=CMC_naefs_hr_latlon0p5x0p5_P${nfhrs}_0${cmcmem}_acc  
    echo " cfopg1='${file}',"   >>namin_${nfhrs}_${nens}_acc
    echo " interhr=$interhr,"   >>namin_${nfhrs}_${nens}_acc
    echo " /" >>namin_${nfhrs}_${nens}_acc

  done

  if [ -s poescript_cmc_${nens}_acc ]; then
    rm poescript_cmc_${nens}_acc
  fi

  for nfhrs in $hourlist; do
    echo "$EXECcmce/${pgm} <namin_${nfhrs}_${nens}_acc > $pgmout.${nfhrs}.${nens}" >> poescript_cmc_${nens}_acc
  done

  if [ -s poescript_cmc_${nens}_acc ]; then
    chmod +x poescript_cmc_${nens}_acc
    startmsg
    $APRUN poescript_cmc_${nens}_acc
    export err=$?; err_chk
  fi
done

set +x
echo " "
echo "Leaving sub script cmcens_post_acc.sh"
echo " "
set -x

