########################################
# Script: gefs_anomefi_acpr.sh 
# ABSTRACT:  This script produces GRIB2
#  files of climate anomaly forecast and EFI
########################################

if [ $# -lt 2 ]; then
   echo "Usage:$0 need input"
   echo "1). YYYYMMDDHH (initial time)"
   echo "2). FHR (forecast hours)     "
   exit 8
fi

set +x
echo " "
echo " Entering sub script climate_anomaly.sh"
echo " iob input initial time is: $CDATE=$1 "
echo " job input forecast time is: $fhr=$2   "
echo " "
set -x

CDATE=$1             
fhr=$2

export EXECGEFS=$HOMEgefs/exec
export pgm=gefs_climate_anfefi_acpr

########################################

cd $DATA
for FHR in $fhr 
do
   ln -fs $COMIN_fcst fcst.dat
   ls -l $COMIN_fcst
   ls -l fcst.dat

   echo "&namin " >input
   echo "cfcst='fcst.dat'," >>input
   echo "cgamma1='gamma1.dat'," >>input
   echo "cgamma2='gamma2.dat'," >>input
   echo "cefi='efi.dat'," >>input
   echo "canom='anom.dat'," >>input
   echo "/" >>input

   startmsg
   $EXECGEFS/$pgm <input > $pgmout.$FHR_an 2> errfile
   export err=$?;err_chk

   mv efi.dat  geprcp.${cycle}.pgrb2a.0p50.efif${FHR}
   mv anom.dat geprcp.${cycle}.pgrb2a.0p50.anvf${FHR}

done

 rm fcst.dat gamma1.dat gamma2.dat 

set +x
echo " "
echo "Leaving sub script climate_anomaly.sh"
echo " "
set -x

