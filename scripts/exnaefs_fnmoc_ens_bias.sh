#!/bin/sh
########################### BIASUPDATE #################################
# script: Update Bias Estimation of FNMOC Global Ensemble Forecast Daily
# AUTHOR: Bo Cui  (wx20cb)"
# History: 
#    Oct 2010 - First implementation of this new script."
#    2022-07-03  Bo Cui - modified for 0.5 degree input
########################### BIASUPDATE #################################

### To submit this job for T00Z, and T12Z , two cycles per day

### need pass the values of PDY, CYC, DATA, COMIN, and COMOUT

################################################################
# define exec variable, and entry grib utility 
################################################################
set -x

export pgm=fnmocens_bias
. prep_step

########################################################
### define the days for searching bias estimation backup
########################################################
###
ymdh=${PDY}${cyc}

###
#  calculate bias estimation between CDAS and FNMOC analysis            
###

if [ "$BIASCDAS" = "YES" ]; then

for nfhrs in 000; do
 for nens in mdf; do

###
#  set the no cold start index as default, 0
###
  cstart=0

###
# FNMOC operational analysis file entry
###

  aymdh=$PDYm1$cyc
  aymd=`echo $aymdh | cut -c1-8`
  acyc=`echo $aymdh | cut -c9-10`
  echo $aymdh $aymd $acyc

  aymdh_m06=`$NDATE -6 $aymdh `
  aymd_m06=`echo $aymdh_m06 | cut -c1-8`
  acyc_m06=`echo $aymdh_m06 | cut -c9-10`

  afile=$COMINnavgem/US058GMET-OPSbd2.NAVGEM000-${aymd}${acyc}-NOAA-halfdeg.gr2

  if [ ! -s $afile ]; then
    echo " FATAL ERROR: There is no FNMOC Analysis data, Stop! for " ${aymd}${acyc}
    export err=1; err_chk
  fi

###
# cfs reanalysi file entry
###

  rfile_in=$COMINcfs/cdas.${aymd}/cdas1.t${acyc}z.pgrbf00.grib2
  rfile_m06in=$COMINcfs/cdas.${aymd_m06}/cdas1.t${acyc_m06}z.pgrbf06.grib2

  rfile=cdas1.t${acyc}z.pgrbf00.0p50.grib2
  rfile_m06=cdas1.t${acyc_m06}z.pgrbf06.0p50.grib2
  grid2="0 6 0 0 0 0 0 0 720 361 0 0 90000000 0 48 -90000000 359500000 500000 500000 0"

  if [ ! -s $rfile_in ]; then
    echo "FATAL ERROR: There is no CFS Reanalysis data, Stop! for " ${aymd}${acyc}
    export err=1; err_chk
  fi
  if [ ! -s $rfile_m06in ]; then
    echo " There is no CFS Reanalysis data, Stop! for " ${aymd_m06}${acyc_m06}
  fi

  $COPYGB2 -g "$grid2" -x $rfile_in    $rfile
  $COPYGB2 -g "$grid2" -x $rfile_m06in $rfile_m06

###
#  get initialized bias between analyais and reanalysis entry
###

  pgbmdf=fnmoc_glbanl.t${cyc}z.pgrb2a.0p50_mdf000
  pgbmean=glbanl.t${cyc}z.pgrb2a.0p50_meandif

  if [ -s $COMINbias/fens.$PDYm2/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/fens.$PDYm2/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/fens.$PDYm3/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/fens.$PDYm3/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/fens.$PDYm4/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/fens.$PDYm4/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/fens.$PDYm5/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/fens.$PDYm5/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/fens.$PDYm6/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/fens.$PDYm6/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/fens.$PDYm7/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/fens.$PDYm7/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  else
    echo " Cold Start for Bias Estimation between CDAS and GDAS Fcst. Hour " $nfhrs 
    cstart=1
  fi

###
#  output bias estimation between CDAS and GDAS            
###

  ofile=fnmoc_glbanl.t${cyc}z.pgrb2a.0p50_mdf000                        

  echo "&message"  >input.$nfhrs.$nens
  echo " icstart=${cstart}," >> input.$nfhrs.$nens
  echo " nens='$nens'," >>input.$nfhrs.$nens
  echo " ifhr=$nfhrs," >>input.$nfhrs.$nens
  echo " dec_w=0.02," >> input.$nfhrs.$nens
  echo " odate=$odate," >>input.$nfhrs.$nens
  echo "/" >>input.$nfhrs.$nens

  ln -sf $pgbmean   fort.11
  ln -sf $afile     fort.12
  ln -sf $rfile     fort.13
  ln -sf $rfile_m06 fort.14
  ln -sf $ofile     fort.51

  startmsg
  $EXECfnmoc/$pgm  <input.$nfhrs.$nens > $pgmout.$nfhrs.${nens} 2> errfile
  export err=$?;err_chk

 done
done
fi

###
#  calculate bias estimation between NCEP and FNMOC analysis: FNMOC anl - NCEP anl
###

if [ "$BIASANL" = "YES" ]; then

rm fort.*

for nfhrs in 000; do
 for nens in anl; do

###
#  set the no cold start index as default, 0
###
  cstart=0

###
# gdas NCEP operational analysis file entry
###

  aymdh=$PDYm1$cyc
  aymd=`echo $aymdh | cut -c1-8`
  acyc=`echo $aymdh | cut -c9-10`

  aymdh_m06=`$NDATE -6 $aymdh `
  aymd_m06=`echo $aymdh_m06 | cut -c1-8`
  acyc_m06=`echo $aymdh_m06 | cut -c9-10`

  nfile=$COMINgefs/gefs.${aymd}/${acyc}/atmos/pgrb2ap5/gec00.t${acyc}z.pgrb2a.0p50.f000

  if [ ! -s $nfile ]; then
    echo " FATAL ERROR:There is no GEFS Analysis data, Stop! for " ${aymd}${acyc}
    export err=1; err_chk
  fi

###
# FNMOC analysi file entry
###

  cfile=$COMINnavgem/US058GMET-OPSbd2.NAVGEM000-${aymd}${acyc}-NOAA-halfdeg.gr2

  if [ ! -s $cfile ]; then
    echo "FATAL ERROR: There is no FNMOC Analysis data, Stop! for " ${aymd}${acyc}
    export err=1; err_chk
  fi

###
#  get initialized bias between NCEP and FNMOC analysis 
###

  pgbmdf=ncepfnmoc_glbanl.t${cyc}z.pgrb2a.0p50_mdf000
  pgbmean=glbanl.t${cyc}z.pgrb2a.0p50_meandif

  if [ -s $COMINbias/gefs.$PDYm2/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm2/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/gefs.$PDYm3/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm3/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/gefs.$PDYm4/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm4/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/gefs.$PDYm5/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm5/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/gefs.$PDYm6/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm6/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/gefs.$PDYm7/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm7/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  else
    echo " Cold Start for Bias Estimation between CDAS and GDAS Fcst. Hour " $nfhrs 
    cstart=1
  fi

###
#  output bias estimation between NCEP and FNMOC analysis   
###

  ofile=ncepfnmoc_glbanl.t${cyc}z.pgrb2a.0p50_mdf000                        

  echo "&message"  >input.$nfhrs.$nens
  echo " icstart=${cstart}," >> input.$nfhrs.$nens
  echo " nens='$nens'," >>input.$nfhrs.$nens
  echo " dec_w=0.10," >> input.$nfhrs.$nens
  echo " odate=$odate," >>input.$nfhrs.$nens
  echo "/" >>input.$nfhrs.$nens

  ln -sf $pgbmean   fort.11
  ln -sf $nfile     fort.12
  ln -sf $cfile     fort.13
  ln -sf $ofile     fort.51

  startmsg
  $EXECfnmoc/$pgm  <input.$nfhrs.$nens > $pgmout.$nfhrs.${nens} 2> ercfile
  export err=$?;err_chk

 done
done
fi

if [ "$SENDCOM" = "YES" ]; then
  file=fnmoc_glbanl.t${cyc}z.pgrb2a.0p50_mdf000
  if [ -s $file ]; then
    cp $file $COMOUT_M1/
  else
    echo "Warning $file missing"
  fi
  file=ncepfnmoc_glbanl.t${cyc}z.pgrb2a.0p50_mdf000
  if [ -s $file ]; then
    cp $file $COMOUTNCEP_M1/
  else
    echo "Warning $file missing"
  fi
fi

msg="HAS COMPLETED NORMALLY!"
postmsg "$jlogfile" "$msg"

exit 0
