#!/bin/sh
########################################
# Script: cmce_weights.sh
# Abstract: this script produces weights of ensemble member
# Author: Yuejian Zhu 
# History: May 2006 - First implementation of this new script
#          Oct 2013 - GRIB2 I/O
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
MEMLIST=$3
workdir=$4

if [ ! -d $workdir ]; then
 mkdir -p $workdir
fi

cd $workdir

PDY=`echo $CDATE | cut -c1-8`
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

 if [ -s input_$ens ]; then
   rm input_$ens
 fi

 ifile_cmc=${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P${FHR}_0${ens}.grib2

 ln -fs $DCOM_IN/${ifile_cmc}              fcst_$ens.dat

 echo "&namin " >input_$ens
 echo "cfcst='fcst_$ens.dat'," >>input_$ens
 echo "cwght='wght_$ens.dat'," >>input_$ens
 echo "members=$members," >>input_$ens
 echo "/" >>input_$ens

 startmsg
 $EXECcmce/$pgm <input_$ens > $pgmout.$FHR.${ens}_wt 2> errfile
 export err=$?;err_chk

 if [ $ens -eq 00 ]; then
   mv wght_$ens.dat cmc_gec${ens}.t${CYC}z.pgrb2a.0p50_wtf${FHR}
 else
   mv wght_$ens.dat cmc_gep${ens}.t${CYC}z.pgrb2a.0p50_wtf${FHR}
 fi

 done

 rm fcst_*.dat 

done

set +x
echo " "
echo "Leaving sub script cmce_weights.sh"
echo " "
set -x
