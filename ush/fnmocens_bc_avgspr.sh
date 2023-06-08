#!/bin/sh
###########################################################################
# Script: fnmocens_bc_avgspr.sh
# Abstract: this script produces mean and spread of FNMOC ensemble forecast
# Author: Bo Cui ---- Oct. 2013
# History:  
#         2022-07-03  Bo Cui - modified for 0.5 degree input
###########################################################################

set -x
cd $DATA

pgm=ens_avgspr

#---------------------------------------
#  calculate ensemble mean and spread
#---------------------------------------

hourlist="000 003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 \
          051 054 057 060 063 066 069 072 075 078 081 084 087 090 093 096 099 \
          102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 \
          153 156 159 162 165 168 171 174 177 180 183 186 189 192 198 204 \
          210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

memberlist="bc001 bc002 bc003 bc004 bc005 bc006 bc007 bc008 bc009 bc010 \
            bc011 bc012 bc013 bc014 bc015 bc016 bc017 bc018 bc019 bc020"

######################################################
# start mean and spread calculation for each lead time
######################################################

for nfhrs in $hourlist
do

  echo " &namens" >>namin_avgspr_${nfhrs}

  ifile=0
  for mem in $memberlist
  do
    file=$COMINBC/ENSEMBLE.halfDegree.MET.fcst_${mem}.${nfhrs}.${PDY}${cyc}
    if [ -s $file ]; then
      (( ifile = ifile + 1 ))
      iskip=0
      echo " cfipg($ifile)='${file}'," >>namin_avgspr_${nfhrs}
      echo " iskip($ifile)=${iskip}," >>namin_avgspr_${nfhrs}
    fi
  done

  echo " nfiles=${ifile}," >>namin_avgspr_${nfhrs}
  echo " cfopg1='fnmoc_geavg.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}'," >>namin_avgspr_${nfhrs}
  echo " cfopg2='fnmoc_gespr.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}'," >>namin_avgspr_${nfhrs}
  echo " /" >>namin_avgspr_${nfhrs}

  if [ $ifile -le 2 ]; then
    echo "FATAL ERROR in fnmocens_bc_avgspr.sh!!!"
    echo "Fewer than 2 FNMOC calibrated files available for fcst hr " $nfhrs
    export err=1; err_chk
  fi

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
    file=fnmoc_geavg.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
    if [ -s $file ]; then
      mv $file $COMOUTBC/
    else
      echo "Warning $file missing"
    fi
    file=fnmoc_gespr.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
    if [ -s $file ]; then
      mv $file $COMOUTBC/
    else
      echo "Warning $file missing"
    fi
  done
fi

set +x
echo " "
echo "Leaving sub script fnmocens_bc_avgspr.sh"
echo " "
set -x

