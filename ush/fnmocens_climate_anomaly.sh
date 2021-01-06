######################################################################
# Script: fnmocens_climate_anomaly.sh 
# Abstract: this script produces GRIB files of climate anomaly forecast
# Author: Bo Cui         
# History: Oct 2010 - First implementation of this new script
######################################################################

if [ $# -lt 2 ]; then
   echo "Usage:$0 need input"
   echo "1). YYYYMMDDHH (initial time)"
   echo "2). FHR (forecast hours)     "
   exit 8
fi

set +x
echo " "
echo " Entering sub script fnmocens_climate_anomaly.sh"
echo " iob input initial time is: $CDATE=$1 "
echo " job input forecast time is: $fhr=$2   "
echo " "
set -x

CDATE=$1             
fhr=$2

YMD=`echo $CDATE | cut -c1-8`
cyc=`echo $CDATE | cut -c9-10`

pgm=gefs_climate_anomaly
###
########################################
# define the time that the bias between CDAS and FNMOC analysis available: $BDATE
########################################
###

for FHR in $fhr 
do

 FDATE=`$NDATE +$FHR $CDATE`
 HH=`echo $FDATE | cut -c9-10`
 MDH=`echo $FDATE | cut -c5-10`         
 MD=`echo $FDATE | cut -c5-8`         
 bcyc=`echo $FDATE | cut -c9-10`

 for ens in $MEMLIST                                         
 do

 rm input_$ens

 ln -fs fnmoc_ge${ens}.t${cyc}z.pgrb2a_bcf${FHR} fcst_$ens.dat
 ln -fs $FIXfnmoc/cmean_1d.1979${MD}          mean_$ens.dat
 ln -fs $FIXfnmoc/cstdv_1d.1979${MD}          stdv_$ens.dat

 ### get analysis difference between CDAS and FNMOC aanalysis

 #####################################################################
 ### use NCEP bias, when CMC data are available, delete this paragraph
 #####################################################################

 ifbias=0
 pgb=fnmoc_glbanl.t${bcyc}z.pgrb2a_mdf00

 if [ -s $COMINbias/fens.${PDYm2}/${bcyc}/pgrb2a/$pgb ]; then
   ln -fs $COMINbias/fens.${PDYm2}/${bcyc}/pgrb2a/$pgb bias_$ens.dat                                    
 elif [ -s $COMINbias/fens.${PDYm3}/${bcyc}/pgrb2a/$pgb ]; then
   ln -fs $COMINbias/fens.${PDYm3}/${bcyc}/pgrb2a/$pgb bias_$ens.dat                                    
 elif [ -s $COMINbias/fens.${PDYm4}/${bcyc}/pgrb2a/$pgb ]; then
   ln -fs $COMINbias/fens.${PDYm4}/${bcyc}/pgrb2a/$pgb bias_$ens.dat                                    
 elif [ -s $COMINbias/fens.${PDYm5}/${bcyc}/pgrb2a/$pgb ]; then
   ln -fs $COMINbias/fens.${PDYm5}/${bcyc}/pgrb2a/$pgb bias_$ens.dat                                    
 elif [ -s $COMINbias/fens.${PDYm6}/${bcyc}/pgrb2a/$pgb ]; then
   ln -fs $COMINbias/fens.${PDYm6}/${bcyc}/pgrb2a/$pgb bias_$ens.dat                                    
 else
   ifbias=1
 fi

 ##################################################################

 echo "&namin " >input_$ens
 echo "cfcst='fcst_$ens.dat'," >>input_$ens
 echo "cmean='mean_$ens.dat'," >>input_$ens
 echo "cstdv='stdv_$ens.dat'," >>input_$ens
 echo "cbias='bias_$ens.dat'," >>input_$ens
 echo "canom='anom_$ens.dat'," >>input_$ens
 echo "ibias=$ifbias," >>input_$ens
 echo "/" >>input_$ens

 startmsg
 $EXECfnmoc/$pgm  <input_$ens >$pgmout.$FHR.${ens}_an 2> errfile
 export err=$?;err_chk

 mv anom_$ens.dat fnmoc_ge${ens}.t${cyc}z.pgrb2a_anf${FHR}

 done

 rm fcst_*.dat mean_*.dat stdv_*.dat bias*.dat

done

set +x
echo " "
echo "Leaving sub script fnmocens_climate_anomaly.sh"
echo " "
set -x

