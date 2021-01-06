#############################################################
# Script: gefs_weights.sh
# Abstract: this script produces weights of ensemble member
# Author: Yuejian Zhu 
# History: May 2006 - First implementation of this new script
#          Oct 2016 - Updated for 0.5d data
#############################################################

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

echo " ***************************************"
echo " JOB INPUT INITIAL  TIME IS: $CDATE "
echo " JOB INPUT FORECAST TIME IS: $fhr   "
echo " ***************************************"

for FHR in $fhr 
do

 members=42

 for ens in $MEMLIST    
 do

 ln -fs $COMINgefs/ge${ens}.t${CYC}z.pgrb2a.0p50.f${FHR} fcst_$ens.dat

 echo "&namin " >input.${FHR}.${ens}_wt
 echo "cfcst='fcst_$ens.dat'," >>input.${FHR}.${ens}_wt
 echo "cwght='wght_$ens.dat'," >>input.${FHR}.${ens}_wt
 echo "members=$members," >>input.${FHR}.${ens}_wt
 echo "/" >>input.${FHR}.${ens}_wt

 startmsg
 $EXECgefs/gefs_weights <input.${FHR}.${ens}_wt >${pgmout}.$FHR.${ens}_wt     
 export err=$?;err_chk

 mv wght_$ens.dat ge${ens}.t${CYC}z.pgrb2a.0p50_wtf${FHR}

 done

 rm fcst_*.dat 

#cat output_$ens

#ls -l ge*.t${CYC}z.pgrb_wtf${FHR}

done

set +x
echo " "
echo "Leaving sub script gefs_weights.sh"
echo " "
set -x
