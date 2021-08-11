#!/bin/sh
######################### CALLED BY EXENSCQPF ##########################
echo "------------------------------------------------"
echo "Ensemble CQPF -> gefs_enspvrfysh  -> gefs_ensgetgrp.sh "
echo "------------------------------------------------"
echo "History: Feb 2004 - First implementation of this new script."
echo "AUTHOR: Yuejian Zhu (wx20yz)"
echo "History: Dec 2011 - Upgrade to 1 degree and 6 hourly"
echo "History: Dec 2013 - Change I/O from GRIB1 to GRIB2"
echo "History: Dec 2016 - Upgrade to 0.5 degree and 6 hourly"
echo "AUTHOR: Yan Luo (wx22lu)"

#set -x 

RUNID=$1
 case $RUNID in 
 gfs) nens=gfs;;
 ctl) nens=c00;;
 esac

  hourlist="    006 012 018 024 030 036 042 048 054 060 066 072 078 084 090 096 \
            102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
            204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
            306 312 318 324 330 336 342 348 354 360 366 372 378 384"

  if [ "$RUNID" = "gfs" ]; then
    hourlist="    006 012 018 024 030 036 042 048 054 060 066 072 078 084 090 096 \
              102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
              204 210 216 222 228 234 240"
  fi

#####################
## fetch gfs/ctl forecasts   
#####################

for nfhrs in $hourlist; do 
 if [ $cyc -eq 18 ]; then 
   nphrs=`expr $nfhrs + $cyc`
   fymdh=`$NDATE -$nphrs $YMDHM12`
   fymd=`echo $fymdh | cut -c1-8`
  else
   nphrs=`expr $nfhrs + $cyc`
   fymdh=`$NDATE -$nphrs $YMDHM12`
   fymd=`echo $fymdh | cut -c1-8`
  fi

 if [ $nfhrs -eq 000 -o $nfhrs -eq 006 -o $nfhrs -eq 012 ]; then
  case $nfhrs in
  000) grptime=000_000;;
  006) grptime=000_006;;
  012) grptime=006_012;; 
  esac
#  echo grptime=$grptime
  else
    nshrs=`expr $nfhrs - 6`
    grptime=$nshrs"_"$nfhrs
    if [ $nfhrs -ge 018 -a $nfhrs -le 102 ]; then
      grptime=0$nshrs"_"$nfhrs
    fi
  fi
    file=ge${nens}.t${cyc}z.pgrb2a.0p50.f${nfhrs}
    infile=$COMINgefs/gefs.$fymd/${cyc}/atmos/pgrb2ap5/$file
    outfile=$DATA/$cyc/$RUNID\_$fymd${cyc}_${grptime}

  if [ -f $infile ]; then
      $WGRIB2 -match ":APCP:" $infile -append -grib $outfile
  else
      echo " No either $infile" 
      echo " Missing precipitation forecast data detected, quit "
#      export err=8; err_chk
  fi     
  done

    aymdh=`$NDATE -$cyc $YMDHM12`
    aymd=`echo $aymdh | cut -c1-8`
    file=ge${nens}.t${cyc}z.pgrb2a.0p50.f006
    infile=$COMINgefs/gefs.$aymd/${cyc}/atmos/pgrb2ap5/$file
    outfile=$DATA/$cyc/precip.${RUNID}"_"t${cyc}z
  if [ -f $infile ]; then
      $WGRIB2 -match ":APCP:" $infile -append -grib $outfile
  else
      echo " No either $infile"
      echo " Missing precipitation forecast data detected, quit "
#     export err=8; err_chk
  fi     
