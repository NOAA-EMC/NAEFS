#!/bin/sh
########################### BIASUPDATE ############################################################
echo "-------------------------------------------------------------"
echo "Update Bias Estimation of CMC Global Ensemble Forecast Daily"
echo "-------------------------------------------------------------"
echo "History: May 2006 - First implementation of this new script."
echo "         Dec 2006 - Modified script for CMC system upgrade (20 members)"
echo "         Oct 2010 - Add 15 new variables for bias estimation "
echo "         Oct 2013 - GRIB2 I/O "
echo "AUTHOR: Bo Cui  (wx20cb)"
########################### BIASUPDATE ############################################################

### To submit this job for T00Z, T06Z T12Z and T18Z, four cycles per day

### need pass the values of PDY, CYC, DATA, COMIN, and COMOUT

################################################################
# define exec variable, and entry grib utility 
################################################################
set -x

export pgm=cmcens_bias
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

###
################################################################
### calculate bias estimation for different forecast lead time
################################################################

if [ "$BIASMEM" = "YES" ]; then
  memberlist="c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"
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


  hourlist="000 003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 \
            051 054 057 060 063 066 069 072 075 078 081 084 087 090 093 096 099 \
            102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 \
            153 156 159 162 165 168 171 174 177 180 183 186 189 192 198 204 \
            210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
            306 312 318 324 330 336 342 348 354 360 366 372 378 384"

  for nfhrs in $hourlist; do

###
# analysis files entry
###

  fymdh=${PDYm2}18
  fymdh=`$NDATE -$nfhrs $fymdh `
  fymd=`echo $fymdh | cut -c1-8`

  aymdh=`$NDATE +$nfhrs $fymd$cyc `
  aymd=`echo $aymdh | cut -c1-8`
  acyc=`echo $aymdh | cut -c9-10`

  afile=$COM_CMC/cmce.${aymd}/${acyc}/pgrb2ap5/cmc_gec00.t${acyc}z.pgrb2a.0p50.anl

###
# set the forecast file as analysis for ULWRF
# CMC ensemble has no 06z and 18z cycle forecasts
###

  if [ $acyc -eq 00 ]; then
    if [ $cyc -eq 00 ]; then
      afile_m12=$COM_CMC/cmce.$PDYm3/12/pgrb2ap5/cmc_ge$nens.t12z.pgrb2a.0p50.f012
      if [ $nfhrs -eq 00 ]; then
        afile_m12=$COM_CMC/cmce.$PDYm2/00/pgrb2ap5/cmc_ge$nens.t00z.pgrb2a.0p50.f000
      fi
    fi
    if [ $cyc -eq 12 ]; then
      afile_m12=$COM_CMC/cmce.$PDYm2/12/pgrb2ap5/cmc_ge$nens.t12z.pgrb2a.0p50.f012
    fi
  elif [ $acyc -eq 06 ]; then
    if [ $cyc -eq 00 ]; then
      afile_m12=$COM_CMC/cmce.$PDYm2/00/pgrb2ap5/cmc_ge$nens.t00z.pgrb2a.0p50.f006
    fi
    if [ $cyc -eq 12 ]; then
      afile_m12=$COM_CMC/cmce.$PDYm1/00/pgrb2ap5/cmc_ge$nens.t00z.pgrb2a.0p50.f006
    fi
  elif [ $acyc -eq 12 ]; then
    afile_m12=$COM_CMC/cmce.$PDYm2/00/pgrb2ap5/cmc_ge$nens.t00z.pgrb2a.0p50.f012
    if [ $nfhrs -eq 00 ]; then
      afile_m12=$COM_CMC/cmce.$PDYm2/12/pgrb2ap5/cmc_ge$nens.t12z.pgrb2a.0p50.f000
    fi
  elif [ $acyc -eq 18 ]; then
    afile_m12=$COM_CMC/cmce.$PDYm2/12/pgrb2ap5/cmc_ge$nens.t12z.pgrb2a.0p50.f006
  fi

###

  if [ -s $afile ]; then
    echo " "
  else
    echo " There is no Analysis data, Stop! for " $acyc 
  fi

  if [ -s $afile_m12 ]; then
    echo " "
  else
    echo " There is no Analysis data for ULWRF, Stop! for " $acyc_m12
  fi

###
# forecast files entry
###

  cfile=$COM_CMC/cmce.${fymd}/${cyc}/pgrb2ap5/cmc_ge$nens.t${cyc}z.pgrb2a.0p50.f$nfhrs  

###
# get initialized bias for $nens at $nfhrs, set the no cold start index as default, 0
###

  cstart=0

  ifile=cmc_ge${nens}.t${cyc}z.pgrb2a.0p50_mef${nfhrs}
  pgbme=bias.ge${nens}.t${cyc}z.f$nfhrs

  if [ -s $COMINbias/cmce.$PDYm2/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/cmce.$PDYm2/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/cmce.$PDYm3/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/cmce.$PDYm3/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/cmce.$PDYm4/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/cmce.$PDYm4/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/cmce.$PDYm5/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/cmce.$PDYm5/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/cmce.$PDYm6/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/cmce.$PDYm6/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/cmce.$PDYm7/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/cmce.$PDYm7/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/cmce.$PDYm8/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/cmce.$PDYm8/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/cmce.$PDYm9/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/cmce.$PDYm9/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/cmce.$PDYm10/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/cmce.$PDYm10/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/cmce.$PDYm11/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/cmce.$PDYm11/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/cmce.$PDYm12/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/cmce.$PDYm12/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/cmce.$PDYm13/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/cmce.$PDYm13/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/cmce.$PDYm14/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/cmce.$PDYm14/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/cmce.$PDYm15/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/cmce.$PDYm15/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/cmce.$PDYm16/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/cmce.$PDYm16/${cyc}/pgrb2ap5/$ifile $pgbme
  else
    echo "Cold Start for Bias Estimation between Analysis and CMC Forecast At " $nfhrs " For " $nens
    cstart=1
  fi

#################################################################
#  input bias estimation 6h ago for tmax and tmin bias estimation
#################################################################

  if [ $nfhrs -ge 06 ]; then

    nfhrsm06=`expr $nfhrs - 06`
    if [ $nfhrsm06 -le 09 ]; then
      bias_m06=cmc_ge${nens}.t${cyc}z.pgrb2a.0p50_mef0$nfhrsm06
    else
      bias_m06=cmc_ge${nens}.t${cyc}z.pgrb2a.0p50_mef$nfhrsm06
    fi

  fi

###
#  output ensemble forecasting bias estimation
###

  ofile=cmc_ge${nens}.t${cyc}z.pgrb2a.0p50_mef${nfhrs}

  rm fort.*
 
# odate=`$NDATE -24 $PDY$cyc `
  odate=`$NDATE -24 $PDYm1$cyc `

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
  $EXECcmce/$pgm  <input.$nfhrs.$nens > $pgmout.$nfhrs.${nens} 2> errfile
  export err=$?;err_chk

 done
done

fi
fi

###
#  calculate bias estimation between CDAS and CMC analysis    
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
# CMC operational analysis file entry
###

  aymdh=$PDYm2$cyc
  aymd=`echo $aymdh | cut -c1-8`
  acyc=`echo $aymdh | cut -c9-10`

  aymdh_m06=`$NDATE -6 $aymdh `
  aymd_m06=`echo $aymdh_m06 | cut -c1-8`
  acyc_m06=`echo $aymdh_m06 | cut -c9-10`
                                                           
  afile=$COM_CMC/cmce.${aymd}/${acyc}/pgrb2ap5/cmc_gec00.t${acyc}z.pgrb2a.0p50.anl

  if [ -s $afile ]; then
    echo " "
  else
    echo " There is no Analysis data, Stop! for " $acyc
#   exit
  fi

###
# cfs reanalysi file entry
###

  rfile_in=$COMINcfs/cdas.${aymd}/cdas1.t${acyc}z.pgrbf00.grib2
  rfile_m06in=$COMINcfs/cdas.${aymd_m06}/cdas1.t${acyc_m06}z.pgrbf06.grib2

  rfile=cdas1.t${acyc}z.pgrbf00.0p50.grib2
  rfile_m06=cdas1.t${acyc_m06}z.pgrbf06.0p50.grib2
  grid2="0 6 0 0 0 0 0 0 720 361 0 0 90000000 0 48 -90000000 359500000 500000 500000 0"

  $COPYGB2 -g "$grid2" -x $rfile_in    $rfile
  $COPYGB2 -g "$grid2" -x $rfile_m06in $rfile_m06

###
#  get initialized bias between analyais and reanalysis entry
###

  pgbmdf=cmc_glbanl.t${cyc}z.pgrb2a.0p50_mdf000
  pgbmean=glbanl.t${cyc}z.pgrb2a_meandif

  if [ -s $COMINbias/cmce.$PDYm3/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/cmce.$PDYm3/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/cmce.$PDYm4/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/cmce.$PDYm4/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/cmce.$PDYm5/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/cmce.$PDYm5/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/cmce.$PDYm6/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/cmce.$PDYm6/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/cmce.$PDYm7/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/cmce.$PDYm7/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  else
    echo " Cold Start for Bias Estimation between CDAS and CMC Analysis " $nfhrs 
    cstart=1
  fi

###
#  output bias estimation between CDAS and GDAS            
###

  ofile=cmc_glbanl.t${cyc}z.pgrb2a.0p50_mdf000                        

  echo "&message"  >input.$nfhrs.$nens
  echo " icstart=${cstart}," >> input.$nfhrs.$nens
  echo " nens='$nens'," >>input.$nfhrs.$nens
  echo " dec_w=0.02," >> input.$nfhrs.$nens
  echo " odate=$odate," >>input.$nfhrs.$nens
  echo "/" >>input.$nfhrs.$nens

  ln -sf $pgbmean   fort.11
  ln -sf $afile     fort.12
  ln -sf $rfile     fort.13
  ln -sf $rfile_m06 fort.14
  ln -sf $ofile     fort.51

  startmsg
  $EXECcmce/$pgm  <input.$nfhrs.$nens > $pgmout.$nfhrs.${nens} 2> errfile
  export err=$?;err_chk

 done
done

fi

if [ "$SENDCOM" = "YES" ]; then
  for nfhrs in $hourlist
  do
    for nens in $memberlist; do
      file=cmc_ge${nens}.t${cyc}z.pgrb2a.0p50_mef${nfhrs}
      if [ -s $file ]; then
        cp $file $COMOUT_M1/
      fi
    done
  done
  file=cmc_glbanl.t${cyc}z.pgrb2a.0p50_mdf000
  if [ -s $file ]; then
    cp $file $COMOUT_M2/
  fi
fi

msg="HAS COMPLETED NORMALLY!"
postmsg "$jlogfile" "$msg"

exit 0
