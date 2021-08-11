########################### BIASUPDATE ############################################################
echo "--------------------------------------------------------------"
echo "Update Bias Estimation of FNMOC Global Ensemble Forecast Daily"
echo "--------------------------------------------------------------"
echo "History: Oct 2010 - First implementation of this new script."
echo "AUTHOR: Bo Cui  (wx20cb)"
########################### BIASUPDATE ############################################################

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
export PDYm8=`$NDATE -192 $ymdh | cut -c1-8`
export PDYm9=`$NDATE -216 $ymdh | cut -c1-8`
export PDYm10=`$NDATE -240 $ymdh | cut -c1-8`
export PDYm11=`$NDATE -264 $ymdh | cut -c1-8`
export PDYm12=`$NDATE -288 $ymdh | cut -c1-8`
export PDYm13=`$NDATE -312 $ymdh | cut -c1-8`
export PDYm14=`$NDATE -336 $ymdh | cut -c1-8`
export PDYm15=`$NDATE -360 $ymdh | cut -c1-8`
export PDYm16=`$NDATE -384 $ymdh | cut -c1-8`

################################################################
### calculate bias estimation for different forecast lead time
################################################################

if [ "$BIASMEM" = "YES" ]; then
  memberlist="p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"
fi

if [ "$BIASAVG" = "YES" ]; then
  memberlist="avg"
fi

if [ "$BIASC00" = "YES" ]; then
  memberlist="c00"
fi

###
# input basic information, member and forecast lead time
###

if [ $cyc -eq 00 -o $cyc -eq 12 ]; then

if [ "$BIASC00" = "YES" -o "$BIASAVG" = "YES" -o "$BIASMEM" = "YES" ]; then

for nens in $memberlist; do

  hourlist=" 00  06  12  18  24  30  36  42  48  54  60  66  72  78  84  90  96 \
            102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
            204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
            306 312 318 324 330 336 342 348 354 360 366 372 378 384"

  for nfhrs in $hourlist; do

###
# analysis files entry
###

  fymdh=${PDYm1}18
  fymdh=`$NDATE -$nfhrs $fymdh `
  fymd=`echo $fymdh | cut -c1-8`

  aymdh=`$NDATE +$nfhrs $fymd$cyc `
  aymd=`echo $aymdh | cut -c1-8`
  acyc=`echo $aymdh | cut -c9-10`

  aymdh_m06=`$NDATE -6 $aymdh `
  aymd_m06=`echo $aymdh_m06 | cut -c1-8`
  acyc_m06=`echo $aymdh_m06 | cut -c9-10`

  $COPYGB2 -g "0 0 0 0 0 0 0 0 360 181 0 0 -90000000 0 48 90000000 359000000 1000000 1000000 64" -i0 -x $COMINnavgem/US058GMET-OPSbd2.NAVGEM000-${aymd}${acyc}-NOAA-halfdeg.gr2 ${aymd}${acyc}-NOAA-1deg.gr2
  afile=${aymd}${acyc}-NOAA-1deg.gr2

###
# set the forecast file as analysis for ULWRF
# FNMOC ensemble has no 06z and 18z cycle forecasts
###

  if [ $acyc -eq 00 -o $acyc -eq 12 ]; then
    afile_m12=$COM_FENS/fens.${aymd}/${acyc}/pgrb2a/fnmoc_ge$nens.t${acyc}z.pgrb2af00
  elif [ $acyc -eq 06 -o $acyc -eq 18 ]; then
    afile_m12=$COM_FENS/fens.${aymd_m06}/${acyc_m06}/pgrb2a/fnmoc_ge$nens.t${acyc_m06}z.pgrb2af06
  fi   

###

  if [ -s $afile ]; then
    echo " "
  else
    echo " WARNING: There is no Analysis data, Stop! for " $acyc 
  fi

  if [ -s $afile_m12 ]; then
    echo " "
  else
    echo " WARNING: There is no Analysis data for ULWRF for " $acyc_m12 
  fi

###
# forecast files entry
###

  cfile=$COM_FENS/fens.${fymd}/${cyc}/pgrb2a/fnmoc_ge$nens.t${cyc}z.pgrb2af$nfhrs  

###
# get initialized bias for $nens at $nfhrs, set the no cold start index as default, 0
###

  cstart=0

  ifile=fnmoc_ge${nens}.t${cyc}z.pgrb2a_mef${nfhrs}
  pgbme=bias.ge${nens}.t${cyc}z.f$nfhrs

  if [ -s $COMINbias/fens.$PDYm1/${cyc}/pgrb2a/$ifile ]; then
    cp $COMINbias/fens.$PDYm1/${cyc}/pgrb2a/$ifile $pgbme
  elif [ -s $COMINbias/fens.$PDYm2/${cyc}/pgrb2a/$ifile ]; then
    cp $COMINbias/fens.$PDYm2/${cyc}/pgrb2a/$ifile $pgbme
  elif [ -s $COMINbias/fens.$PDYm3/${cyc}/pgrb2a/$ifile ]; then
    cp $COMINbias/fens.$PDYm3/${cyc}/pgrb2a/$ifile $pgbme
  elif [ -s $COMINbias/fens.$PDYm4/${cyc}/pgrb2a/$ifile ]; then
    cp $COMINbias/fens.$PDYm4/${cyc}/pgrb2a/$ifile $pgbme
  elif [ -s $COMINbias/fens.$PDYm5/${cyc}/pgrb2a/$ifile ]; then
    cp $COMINbias/fens.$PDYm5/${cyc}/pgrb2a/$ifile $pgbme
  elif [ -s $COMINbias/fens.$PDYm6/${cyc}/pgrb2a/$ifile ]; then
    cp $COMINbias/fens.$PDYm6/${cyc}/pgrb2a/$ifile $pgbme
  elif [ -s $COMINbias/fens.$PDYm7/${cyc}/pgrb2a/$ifile ]; then
    cp $COMINbias/fens.$PDYm7/${cyc}/pgrb2a/$ifile $pgbme
  elif [ -s $COMINbias/fens.$PDYm8/${cyc}/pgrb2a/$ifile ]; then
    cp $COMINbias/fens.$PDYm8/${cyc}/pgrb2a/$ifile $pgbme
  elif [ -s $COMINbias/fens.$PDYm9/${cyc}/pgrb2a/$ifile ]; then
    cp $COMINbias/fens.$PDYm9/${cyc}/pgrb2a/$ifile $pgbme
  elif [ -s $COMINbias/fens.$PDYm10/${cyc}/pgrb2a/$ifile ]; then
    cp $COMINbias/fens.$PDYm10/${cyc}/pgrb2a/$ifile $pgbme
  elif [ -s $COMINbias/fens.$PDYm11/${cyc}/pgrb2a/$ifile ]; then
    cp $COMINbias/fens.$PDYm11/${cyc}/pgrb2a/$ifile $pgbme
  elif [ -s $COMINbias/fens.$PDYm12/${cyc}/pgrb2a/$ifile ]; then
    cp $COMINbias/fens.$PDYm12/${cyc}/pgrb2a/$ifile $pgbme
  elif [ -s $COMINbias/fens.$PDYm13/${cyc}/pgrb2a/$ifile ]; then
    cp $COMINbias/fens.$PDYm13/${cyc}/pgrb2a/$ifile $pgbme
  elif [ -s $COMINbias/fens.$PDYm14/${cyc}/pgrb2a/$ifile ]; then
    cp $COMINbias/fens.$PDYm14/${cyc}/pgrb2a/$ifile $pgbme
  elif [ -s $COMINbias/fens.$PDYm15/${cyc}/pgrb2a/$ifile ]; then
    cp $COMINbias/fens.$PDYm15/${cyc}/pgrb2a/$ifile $pgbme
  elif [ -s $COMINbias/fens.$PDYm16/${cyc}/pgrb2a/$ifile ]; then
    cp $COMINbias/fens.$PDYm16/${cyc}/pgrb2a/$ifile $pgbme
  else
    echo "Cold Start for Bias Estimation between Analysis and FNMOC Forecast At " $nfhrs " For " $nens
    cstart=1
  fi

#################################################################
#  input bias estimation 6h ago for tmax and tmin bias estimation
#################################################################

  if [ $nfhrs -ge 06 ]; then

    nfhrsm06=`expr $nfhrs - 06`
    if [ $nfhrsm06 -le 09 ]; then
      bias_m06=fnmoc_ge${nens}.t${cyc}z.pgrb2a_mef0$nfhrsm06
    else
      bias_m06=fnmoc_ge${nens}.t${cyc}z.pgrb2a_mef$nfhrsm06
    fi

  fi

###
#  output ensemble forecasting bias estimation
###

  ofile=fnmoc_ge${nens}.t${cyc}z.pgrb2a_mef${nfhrs}

  rm fort.*
 
  odate=`$NDATE -24 $PDY$cyc `

  echo "&message"  >input.$nfhrs.$nens
  echo " icstart=${cstart}," >> input.$nfhrs.$nens
  echo " nens='$nens'," >>input.$nfhrs.$nens
  echo " ifhr=$nfhrs," >>input.$nfhrs.$nens
  echo " dec_w=0.02," >> input.$nfhrs.$nens
  echo " odate=$odate," >>input.$nfhrs.$nens
  echo "/" >>input.$nfhrs.$nens
  
  ln -sf $pgbme     fort.11
  ln -sf $afile     fort.12
  ln -sf $afile_m12 fort.13
  ln -sf $cfile     fort.14
  if [ $nfhrs -ge 06 ]; then
    ln -sf $bias_m06  fort.15
  fi
  ln -sf $ofile     fort.51

  startmsg
  $EXECfnmoc/$pgm  <input.$nfhrs.$nens > $pgmout.$nfhrs.${nens} 2> errfile
  export err=$?;err_chk

 done
done

fi
fi

###
#  calculate bias estimation between CDAS and FNMOC analysis            
###

if [ "$BIASCDAS" = "YES" ]; then

rm fort.*

for nfhrs in 00; do
 for nens in mdf; do

###
#  set the no cold start index as default, 0
###
  cstart=0

###
# FNMOC operational analysis file entry
###

  aymdh=$PDYm2$cyc
  aymd=`echo $aymdh | cut -c1-8`
  acyc=`echo $aymdh | cut -c9-10`
  echo $aymdh $aymd $acyc

  aymdh_m06=`$NDATE -6 $aymdh `
  aymd_m06=`echo $aymdh_m06 | cut -c1-8`
  acyc_m06=`echo $aymdh_m06 | cut -c9-10`

  $COPYGB2 -g "0 0 0 0 0 0 0 0 360 181 0 0 -90000000 0 48 90000000 359000000 1000000 1000000 64" -i0 -x $COMINnavgem/US058GMET-OPSbd2.NAVGEM000-${aymd}${acyc}-NOAA-halfdeg.gr2 ${aymd}${acyc}-NOAA-1deg.gr2
  afile=${aymd}${acyc}-NOAA-1deg.gr2

  if [ -s $afile ]; then
    echo " "
  else
    echo " There is no Analysis data, Stop! for " $acyc
#   exit
  fi

###
# cfs reanalysi file entry
###

  rfile=$COMINcfs/cdas.${aymd}/cdas1.t${acyc}z.pgrbf00.grib2
  rfile_m06=$COMINcfs/cdas.${aymd_m06}/cdas1.t${acyc_m06}z.pgrbf06.grib2

###
#  get initialized bias between analyais and reanalysis entry
###

  pgbmdf=fnmoc_glbanl.t${cyc}z.pgrb2a_mdf00
  pgbmean=glbanl.t${cyc}z.pgrb2a_meandif

  if [ -s $COMINbias/fens.$PDYm3/${cyc}/pgrb2a/$pgbmdf ]; then
    cp $COMINbias/fens.$PDYm3/${cyc}/pgrb2a/$pgbmdf $pgbmean
  elif [ -s $COMINbias/fens.$PDYm4/${cyc}/pgrb2a/$pgbmdf ]; then
    cp $COMINbias/fens.$PDYm4/${cyc}/pgrb2a/$pgbmdf $pgbmean
  elif [ -s $COMINbias/fens.$PDYm5/${cyc}/pgrb2a/$pgbmdf ]; then
    cp $COMINbias/fens.$PDYm5/${cyc}/pgrb2a/$pgbmdf $pgbmean
  elif [ -s $COMINbias/fens.$PDYm6/${cyc}/pgrb2a/$pgbmdf ]; then
    cp $COMINbias/fens.$PDYm6/${cyc}/pgrb2a/$pgbmdf $pgbmean
  elif [ -s $COMINbias/fens.$PDYm7/${cyc}/pgrb2a/$pgbmdf ]; then
    cp $COMINbias/fens.$PDYm7/${cyc}/pgrb2a/$pgbmdf $pgbmean
  else
    echo " Cold Start for Bias Estimation between CDAS and GDAS Fcst. Hour " $nfhrs 
    cstart=1
  fi

###
#  output bias estimation between CDAS and GDAS            
###

  ofile=fnmoc_glbanl.t${cyc}z.pgrb2a_mdf00                        

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

for nfhrs in 00; do
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

  $COPYGB2 -g "0 6 0 0 0 0 0 0 360 181 0 0 90000000 0 48 -90000000 359000000 1000000 1000000 0" -i0 -x $COMINgefs/gefs.${aymd}/${acyc}/atmos/pgrb2ap5/gec00.t${acyc}z.pgrb2a.0p50.f000 gec00.t${acyc}z.pgrb2af00   

  nfile=gec00.t${acyc}z.pgrb2af00     

  if [ -s $nfile ]; then
    echo " "
  else
    echo " There is no Analysis data, Stop! for " $acyc
#   exit
  fi

###
# FNMOC analysi file entry
###

  $COPYGB2 -g "0 0 0 0 0 0 0 0 360 181 0 0 -90000000 0 48 90000000 359000000 1000000 1000000 64" -i0 -x $COMINnavgem/US058GMET-OPSbd2.NAVGEM000-${aymd}${acyc}-NOAA-halfdeg.gr2 ${aymd}${acyc}-NOAA-1deg.gr2
  cfile=${aymd}${acyc}-NOAA-1deg.gr2

###
#  get initialized bias between NCEP and FNMOC analysis 
###

  pgbmdf=ncepfnmoc_glbanl.t${cyc}z.pgrb2a_mdf00
  pgbmean=glbanl.t${cyc}z.pgrb2a_meandif

  if [ -s $COMINbias/gefs.$PDYm2/${cyc}/pgrb2a/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm2/${cyc}/pgrb2a/$pgbmdf $pgbmean
  elif [ -s $COMINbias/gefs.$PDYm3/${cyc}/pgrb2a/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm3/${cyc}/pgrb2a/$pgbmdf $pgbmean
  elif [ -s $COMINbias/gefs.$PDYm4/${cyc}/pgrb2a/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm4/${cyc}/pgrb2a/$pgbmdf $pgbmean
  elif [ -s $COMINbias/gefs.$PDYm5/${cyc}/pgrb2a/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm5/${cyc}/pgrb2a/$pgbmdf $pgbmean
  elif [ -s $COMINbias/gefs.$PDYm6/${cyc}/pgrb2a/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm6/${cyc}/pgrb2a/$pgbmdf $pgbmean
  elif [ -s $COMINbias/gefs.$PDYm7/${cyc}/pgrb2a/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm7/${cyc}/pgrb2a/$pgbmdf $pgbmean
  else
    echo " Cold Start for Bias Estimation between CDAS and GDAS Fcst. Hour " $nfhrs 
    cstart=1
  fi

###
#  output bias estimation between NCEP and FNMOC analysis   
###

  ofile=ncepfnmoc_glbanl.t${cyc}z.pgrb2a_mdf00                        

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

hourlist=" 00  06  12  18  24  30  36  42  48  54  60  66  72  78  84  90  96 \
          102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
          204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

if [ "$SENDCOM" = "YES" ]; then
  for nfhrs in $hourlist
  do
    for nens in $memberlist; do
      file=fnmoc_ge${nens}.t${cyc}z.pgrb2a_mef${nfhrs}
      if [ -s $file ]; then
        cp $file $COMOUT/
      fi
    done
  done
  file=fnmoc_glbanl.t${cyc}z.pgrb2a_mdf00
  if [ -s $file ]; then
    cp $file $COMOUT_M2/
  fi
  file=ncepfnmoc_glbanl.t${cyc}z.pgrb2a_mdf00
  if [ -s $file ]; then
    cp $file $COMOUTNCEP_M1/
  fi
fi

msg="HAS COMPLETED NORMALLY!"
postmsg "$jlogfile" "$msg"

exit 0
