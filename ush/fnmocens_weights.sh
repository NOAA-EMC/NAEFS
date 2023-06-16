#!/bin/sh
########################################
# Script: fnmocens_weights.sh
# Abstract: this script produces weights of ensemble member
# Author: Bo Cui       
# History: Oct 2010 - First implementation of this new script
#         2022-07-03  Bo Cui - modified for 0.5 degree input
########################################

set -x
if [ $# -lt 2 ]; then
   echo "Usage:$0 need input"
   echo "1). YYYYMMDDHH (initial time)"
   echo "2). FHR (forecast hours)     "
   exit 8
fi

CDATE=$1             
fhr=$2
YMD=`echo $CDATE | cut -c1-8`
CYC=`echo $CDATE | cut -c9-10`

pgm=gefs_weights

echo " ***************************************"
echo " JOB INPUT INITIAL  TIME IS: $CDATE "
echo " JOB INPUT FORECAST TIME IS: $fhr   "
echo " ***************************************"

for FHR in $fhr 
do

 members=62

 for ens in $MEMLIST    
 do

 ln -sf fnmoc_ge${ens}.t${CYC}z.pgrb2a.0p50_bcf${FHR} fcst_$ens.dat

 echo "&namin " >input_$ens
 echo "cfcst='fcst_$ens.dat'," >>input_$ens
 echo "cwght='wght_$ens.dat'," >>input_$ens
 echo "members=$members," >>input_$ens
 echo "/" >>input_$ens

 startmsg
 $EXECfnmoc/$pgm         <input_$ens > $pgmout.$FHR.${ens}_wt 2> errfile
 export err=$?;err_chk

 mv wght_$ens.dat fnmoc_ge${ens}.t${CYC}z.pgrb2a.0p50_wtf${FHR}

 done

 rm fcst_$ens.dat input_$ens

done

set +x
echo " "
echo "Leaving sub script fnmocens_weights.sh"
echo " "
set -x
