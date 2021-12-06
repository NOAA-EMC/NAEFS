#!/bin/sh
#####################################################################################
# Script: naefs_climate_anv.sh    
# ABSTRACT:  This script calculte difference between ensemble average and climatology
#####################################################################################
set -x

if [ $# -lt 2 ]; then
   echo "Usage:$0 need input"
   echo "1). YYYYMMDDHH (initial time)"
   echo "2). FHR (forecast hours)     "
   exit 8
fi

set +x
echo " "
echo " Entering sub script naefs_climate_anv.sh "
echo " iob input initial time is: $CDATE=$1 "
echo " job input forecast time is: $fhr=$2   "
echo " "
set -x

CDATE=$1             
fhr=$2

YMD=`echo $CDATE | cut -c1-8`
cyc=`echo $CDATE | cut -c9-10`

export pgm=naefs_climate_anv

###
#######################################################################
# define the time that the bias between CDAS and GDAS available: $BDATE
#######################################################################
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

 ln -fs ge${ens}.t${cyc}z.pgrb2a.0p50_bcf${FHR} fcst_$ens.dat
 ln -fs $FIXnaefs/cmean_p5d.1979${MD}           mean_$ens.dat
 ln -fs $FIXnaefs/cstdv_p5d.1979${MD}           stdv_$ens.dat

 ### get analysis difference between CDAS and GDAS
 ### note: "cyc" will be defined by forecast valid time - Yuejian Zhu

 ### set ifbias=0 as default, bias information available

 ifbias=0

 infile=glbanl.t${bcyc}z.pgrb2a.0p50_mdf000 

 if [ -s $COM_NCEPANL/gefs.${PDYm1}/${bcyc}/pgrb2ap5/${infile} ]; then
   ln -fs $COM_NCEPANL/gefs.${PDYm1}/${bcyc}/pgrb2ap5/${infile} bias_$ens.dat
 elif [ -s $COM_NCEPANL/gefs.${PDYm2}/${bcyc}/pgrb2ap5/${infile} ]; then
   ln -fs $COM_NCEPANL/gefs.${PDYm2}/${bcyc}/pgrb2ap5/${infile} bias_$ens.dat
 elif [ -s $COM_NCEPANL/gefs.${PDYm3}/${bcyc}/pgrb2ap5/${infile} ]; then
   ln -fs $COM_NCEPANL/gefs.${PDYm3}/${bcyc}/pgrb2ap5/${infile} bias_$ens.dat
 elif [ -s $COM_NCEPANL/gefs.${PDYm4}/${bcyc}/pgrb2ap5/${infile} ]; then
   ln -fs $COM_NCEPANL/gefs.${PDYm4}/${bcyc}/pgrb2ap5/${infile} bias_$ens.dat
 elif [ -s $COM_NCEPANL/gefs.${PDYm5}/${bcyc}/pgrb2ap5/${infile} ]; then
   ln -fs $COM_NCEPANL/gefs.${PDYm5}/${bcyc}/pgrb2ap5/${infile} bias_$ens.dat
 elif [ -s $COM_NCEPANL/gefs.${PDYm6}/${bcyc}/pgrb2ap5/${infile} ]; then
   ln -fs $COM_NCEPANL/gefs.${PDYm6}/${bcyc}/pgrb2ap5/${infile} bias_$ens.dat
 else
   ifbias=1
 fi

 echo "&namin " >input_$ens.$FHR
 echo "cfcst='fcst_$ens.dat'," >>input_$ens.$FHR
 echo "cmean='mean_$ens.dat'," >>input_$ens.$FHR
 echo "cstdv='stdv_$ens.dat'," >>input_$ens.$FHR
 echo "cbias='bias_$ens.dat'," >>input_$ens.$FHR
 echo "canom='anom_$ens.dat'," >>input_$ens.$FHR
 echo "ibias=$ifbias," >>input_$ens.$FHR
 echo "/" >>input_$ens.$FHR

 startmsg
 $EXECnaefs/$pgm <input_$ens.$FHR > $pgmout.$FHR.${ens}_an 2> errfile
 export err=$?;err_chk

 mv anom_$ens.dat ge${ens}.t${cyc}z.pgrb2a.0p50_anvf${FHR}

 done

 rm fcst_*.dat mean_*.dat stdv_*.dat bias_*dat input_$ens.$FHR

done

set +x
echo " "
echo "Leaving sub script naefs_climate_anv.sh"
echo " "
set -x

