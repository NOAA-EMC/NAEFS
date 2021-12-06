#!/bin/sh
###########################################################################
# Script: fnmocens_bc_avgspr.sh
# Abstract: this script produces mean and spread of FNMOC ensemble forecast
# Author: Bo Cui ---- Oct. 2013
###########################################################################

set -x
cd $DATA

pgm=ens_avgspr

#---------------------------------------
#  calculate ensemble mean and spread
#---------------------------------------

hourlist=" 00  06  12  18  24  30  36  42  48  54  60  66  72  78  84  90  96 \
          102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
          204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

memberlist="p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 \
            p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"

######################################################
# start mean and spread calculation for each lead time
######################################################

for nfhrs in $hourlist
do

  echo " &namens" >>namin_avgspr_${nfhrs}

  ifile=0
  for mem in $memberlist
  do
    fensmem=`echo $mem | cut -c2-3`
    if [ $nfhrs -le 99 ];then
      file=$COMINBC/ENSEMBLE.MET.fcst_bc0${fensmem}.0${nfhrs}.${PDY}${cyc}
      if [ $nfhrs -eq 00 ];then
        file=$COMINBC/ENSEMBLE.MET.fcst_bc0${fensmem}.000.${PDY}${cyc}
      fi
    else
      file=$COMINBC/ENSEMBLE.MET.fcst_bc0${fensmem}.${nfhrs}.${PDY}${cyc}
    fi
    if [ -s $file ]; then
      (( ifile = ifile + 1 ))
      iskip=0
      echo " cfipg($ifile)='${file}'," >>namin_avgspr_${nfhrs}
      echo " iskip($ifile)=${iskip}," >>namin_avgspr_${nfhrs}
    fi
  done

  echo " nfiles=${ifile}," >>namin_avgspr_${nfhrs}
  echo " cfopg1='fnmoc_geavg.t${cyc}z.pgrb2a_bcf${nfhrs}'," >>namin_avgspr_${nfhrs}
  echo " cfopg2='fnmoc_gespr.t${cyc}z.pgrb2a_bcf${nfhrs}'," >>namin_avgspr_${nfhrs}
  echo " /" >>namin_avgspr_${nfhrs}

done

for nfhrs in $hourlist; do
  echo "$EXECfnmoc/${pgm} <namin_avgspr_${nfhrs} > $pgmout.${nfhrs}_avgspr" >> poescript_avgspr
done

chmod +x poescript_avgspr
startmsg
$APRUN poescript_avgspr
export err=$?; err_chk

wait

if [ "$SENDCOM" = "YES" ]; then
  for nfhrs in $hourlist
  do
    file=fnmoc_geavg.t${cyc}z.pgrb2a_bcf$nfhrs
    if [ -s $file ]; then
      mv $file $COMOUTBC/
    fi
    file=fnmoc_gespr.t${cyc}z.pgrb2a_bcf$nfhrs
    if [ -s $file ]; then
      mv $file $COMOUTBC/
    fi
  done
fi

set +x
echo " "
echo "Leaving sub script fnmocens_bc_avgspr.sh"
echo " "
set -x

