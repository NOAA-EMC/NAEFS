######################################################################
# Script: cmce_climate_anomaly.sh 
# Abstract: this script produces GRIB files of climate anomaly forecast
# Author: Yuejian Zhu
# History: May 2006 - First implementation of this new script
#          Oct 2013 - GRIB2 I/O
######################################################################

if [ $# -lt 2 ]; then
   echo "Usage:$0 need input"
   echo "1). YYYYMMDDHH (initial time)"
   echo "2). FHR (forecast hours)     "
   exit 8
fi

set +x
echo " "
echo " Entering sub script cmce_climate_anomaly.sh"
echo " iob input initial time is: $CDATE=$1 "
echo " job input forecast time is: $fhr=$2   "
echo " "
set -x

CDATE=$1             
fhr=$2
MEMLIST=$3
workdir=$4

if [ ! -d $workdir ]; then
 mkdir -p $workdir
fi

cd $workdir

PDY=`echo $CDATE | cut -c1-8`
cyc=`echo $CDATE | cut -c9-10`

pgm=gefs_climate_anomaly

###
########################################
# define the time that the bias between CDAS and GDAS available: $BDATE
########################################
###

for FHR in $fhr 
do

 FDATE=`$NDATE +$FHR $CDATE`
 MD=`echo $FDATE | cut -c5-8`         
 bcyc=`echo $FDATE | cut -c9-10`

 for ens in $MEMLIST                                         
 do

 if [ -s input.${FHR}.${ens}_an ]; then
   rm input.${FHR}.${ens}_an
 fi

 ifile_cmc=${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P${FHR}_0${ens}.grib2

 ln -fs $DCOM_IN/${ifile_cmc}              fcst_$ens.dat 
 ln -fs $FIXcmce/cmean_p5d.1979${MD}       mean_$ens.dat
 ln -fs $FIXcmce/cstdv_p5d.1979${MD}       stdv_$ens.dat

 ### get analysis difference between CDAS and GDAS

 #####################################################################
 ### use NCEP bias, when CMC data are available, delete this paragraph
 #####################################################################

 ifbias=0
 pgb=cmc_glbanl.t${bcyc}z.pgrb2a.0p50_mdf000

 if [ -s $COMINbias/cmce.${PDYm2}/${bcyc}/pgrb2ap5/$pgb ]; then
   ln -fs $COMINbias/cmce.${PDYm2}/${bcyc}/pgrb2ap5/$pgb bias_$ens.dat 
 elif [ -s $COMINbias/cmce.${PDYm3}/${bcyc}/pgrb2ap5/$pgb ]; then
   ln -fs $COMINbias/cmce.${PDYm3}/${bcyc}/pgrb2ap5/$pgb bias_$ens.dat
 elif [ -s $COMINbias/cmce.${PDYm4}/${bcyc}/pgrb2ap5/$pgb ]; then
   ln -fs $COMINbias/cmce.${PDYm4}/${bcyc}/pgrb2ap5/$pgb bias_$ens.dat
 elif [ -s $COMINbias/cmce.${PDYm5}/${bcyc}/pgrb2ap5/$pgb ]; then
   ln -fs $COMINbias/cmce.${PDYm5}/${bcyc}/pgrb2ap5/$pgb bias_$ens.dat
 elif [ -s $COMINbias/cmce.${PDYm6}/${bcyc}/pgrb2ap5/$pgb ]; then
   ln -fs $COMINbias/cmce.${PDYm6}/${bcyc}/pgrb2ap5/$pgb bias_$ens.dat
 else
   ifbias=1
 fi

 ##################################################################

 echo "&namin " >input.${FHR}.${ens}_an
 echo "cfcst='fcst_$ens.dat'," >>input.${FHR}.${ens}_an
 echo "cmean='mean_$ens.dat'," >>input.${FHR}.${ens}_an
 echo "cstdv='stdv_$ens.dat'," >>input.${FHR}.${ens}_an
 echo "cbias='bias_$ens.dat'," >>input.${FHR}.${ens}_an
 echo "canom='anom_$ens.dat'," >>input.${FHR}.${ens}_an
 echo "ibias=$ifbias," >>input.${FHR}.${ens}_an
 echo "/" >>input.${FHR}.${ens}_an

 startmsg
 $EXECcmce/$pgm  <input.${FHR}.${ens}_an > $pgmout.$FHR.${ens}_an 2> errfile
 export err=$?;err_chk

 if [ $ens -eq 00 ]; then
   mv anom_$ens.dat cmc_gec${ens}.t${cyc}z.pgrb2a.0p50_anf${FHR}
 else
   mv anom_$ens.dat cmc_gep${ens}.t${cyc}z.pgrb2a.0p50_anf${FHR}
 fi

 done

 rm fcst_*.dat mean_*.dat stdv_*.dat bias*.dat

done

set +x
echo " "
echo "Leaving sub script cmce_climate_anomaly.sh"
echo " "
set -x

