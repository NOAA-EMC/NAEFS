#!/bin/sh
##########################################################################################
# Script: gefs_bias_decay.sh
# Abstract: update bias estimation of GEFS & GFS forecast daily
# Author: Bo Cui ---- Oct. 2016
# History:
#        May 2006 - First implementation of this new script.
#        Dec 2006 - Modified script for GEFS system upgrade (20 members)
#        May 2007 - Modified script to include GFS forecast bias estimation
#        Jan 2008 - Add bias estimation calculation between NCEP & CMC analysis (CMC-NCEP)
#        Apr 2009 - Add 14 new variables for bias estimation 
#        Dec 2010 - Add 1 new variables for bias estimation 
#        Mar 2013 - Replace GRIB1 by GRIB2 
#        Jun 2015 - Add new variable (TCDC) 
#        Aug 2016 - Modified script for GEFS 0.5 degree data 
##########################################################################################

##############################################
# define exec variable, and entry grib utility 
##############################################
set -x

mkdir -p $DATA/dir_decay
cd $DATA/dir_decay

export pgm=gefs_bias
. prep_step

########################################################
### define the days for searching bias estimation backup
########################################################

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

###
# input basic information, member and forecast lead time
###

for nens in $memberlist; do

  if [ "$RUNJOB" = "EXTEND" ]; then
    hourlist="  390 396 402 408 414 420 426 432 438 444 450 456 462 468 474 480 \
                486 492 498 504 510 516 522 528 534 540 546 552 558 564 570 576 \
                582 588 594 600 606 612 618 624 630 636 642 648 654 660 666 672 \
                678 684 690 696 702 708 714 720 726 732 738 744 750 756 762 768 \
                774 780 786 792 798 804 810 816 822 828 834 840 "
  fi

  hours=$hrlist_6hr

  if [ "$nens" = "gfs" ]; then
    hours=$hrlist_gfs
  fi

  for nfhrs in $hours; do

###
# analysis files entry
###

# fymdh=${PDYm1}18
  fymdh=${PDYm1}21
  fymdh=`$NDATE -$nfhrs $fymdh `
  fymd=`echo $fymdh | cut -c1-8`

  aymdh=`$NDATE +$nfhrs $fymd$cyc `
  aymd=`echo $aymdh | cut -c1-8`
  acyc=`echo $aymdh | cut -c9-10`

  rem=`echo "${nfhrs}%6" | bc`

  if [ $rem -eq 0 ]; then
    echo "$nfhrs is even number"
    aymdh_m06=`$NDATE -6 $aymdh `
    aymd_m06=`echo $aymdh_m06 | cut -c1-8`
    acyc_m06=`echo $aymdh_m06 | cut -c9-10`
    afile=$COMINgefs/gefs.${aymd}/${acyc}/atmos/pgrb2ap5/gec00.t${acyc}z.pgrb2a.0p50.f000
    afile_m06=$COMINgefs/gefs.${aymd_m06}/${acyc_m06}/atmos/pgrb2ap5/gec00.t${acyc_m06}z.pgrb2a.0p50.f006
    if [ "$nens" = "gfs" ]; then
      afile=$COMINgefs/gefs.${aymd}/${acyc}/atmos/pgrb2ap5/gegfs.t${acyc}z.pgrb2a.0p50.f000
      afile_m06=$COMINgefs/gefs.${aymd_m06}/${acyc_m06}/atmos/pgrb2ap5/gegfs.t${acyc_m06}z.pgrb2a.0p50.f006
    fi
  else
    echo "$nfhrs is odd number"
  fi

  icnt=0
  while [ $icnt -le 30 ]; do
    if [ -s $afile -a -s $afile_m06  ]; then
      icnt=31 
    else
      echo " Warning !!!! There is no GEFS Analysis data $afile or $afile_m06 "
      sleep 1
      icnt=`expr $icnt + 1`
    fi
  done

###
# forecast files entry
###

  cfile=$COMINgefs/gefs.${fymd}/${cyc}/atmos/pgrb2ap5/ge$nens.t${cyc}z.pgrb2a.0p50.f$nfhrs  

  icnt=0
  while [ $icnt -le 30 ]; do
    if [ -s $cfile ]; then
      icnt=31 
    else
      echo " Warning !!!! There is no Forecast for hour $nfhrs - $cfile"
      sleep 1
      icnt=`expr $icnt + 1`
    fi
  done

###
# get initialized bias for $nens at $nfhrs, set the no cold start index as default, 0
###

  cstart=0

  ifile=ge${nens}.t${cyc}z.pgrb2a.0p50_mef${nfhrs}
  pgbme=bias.ge${nens}.t${cyc}z.f$nfhrs

  if [ -s $COMINbias/gefs.$PDYm1/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/gefs.$PDYm1/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/gefs.$PDYm2/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/gefs.$PDYm2/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/gefs.$PDYm3/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/gefs.$PDYm3/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/gefs.$PDYm4/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/gefs.$PDYm4/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/gefs.$PDYm5/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/gefs.$PDYm5/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/gefs.$PDYm6/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/gefs.$PDYm6/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/gefs.$PDYm7/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/gefs.$PDYm7/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/gefs.$PDYm8/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/gefs.$PDYm8/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/gefs.$PDYm9/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/gefs.$PDYm9/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/gefs.$PDYm10/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/gefs.$PDYm10/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/gefs.$PDYm11/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/gefs.$PDYm11/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/gefs.$PDYm12/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/gefs.$PDYm12/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/gefs.$PDYm13/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/gefs.$PDYm13/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/gefs.$PDYm14/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/gefs.$PDYm14/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/gefs.$PDYm15/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/gefs.$PDYm15/${cyc}/pgrb2ap5/$ifile $pgbme
  elif [ -s $COMINbias/gefs.$PDYm16/${cyc}/pgrb2ap5/$ifile ]; then
    cp $COMINbias/gefs.$PDYm16/${cyc}/pgrb2ap5/$ifile $pgbme
  else
    echo "Cold Start for Bias Estimation between Analysis and NCEP Forecast At " $nfhrs " For " $nens
    cstart=1
  fi

###
#  output ensemble forecasting bias estimation
###

  ofile=ge${nens}.t${cyc}z.pgrb2a.0p50_mef${nfhrs}

  rm fort.*
 
  odate=`$NDATE -24 $PDY$cyc `

  if [ "$VARWEIGHT" = "YES" ]; then
    if [ $nfhrs -le 72 ]; then
      dec_w=0.05
    elif [ $nfhrs -eq 78 ]; then
      dec_w=0.04
    elif [ $nfhrs -eq 84 ]; then
      dec_w=0.03
    elif [ $nfhrs -ge 90 -a $nfhrs -le 168 ]; then
      dec_w=0.02
    elif [ $nfhrs -ge 174 ]; then
      dec_w=0.01
    fi
  else
    dec_w=0.02
  fi

  echo "&message"  >input.$nfhrs.$nens
  echo " icstart=${cstart}," >> input.$nfhrs.$nens
  echo " nens='$nens'," >>input.$nfhrs.$nens
  echo " dec_w=${dec_w}," >> input.$nfhrs.$nens
  echo " odate=$odate," >>input.$nfhrs.$nens
  echo "/" >>input.$nfhrs.$nens
  
  ln -sf $pgbme       fort.11
  ln -sf $afile       fort.12
  ln -sf $afile_m06   fort.13
  ln -sf $cfile       fort.14
  ln -sf $ofile       fort.51

  startmsg
  $EXECgefs/$pgm <input.$nfhrs.$nens > $pgmout.$nfhrs.${nens} 2> errfile
  export err=$?;err_chk

 done
done

###
#  calculate bias estimation between CDAS and GDAS            
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
# gdas operational analysis file entry
###

  aymdh=$PDYm1$cyc
  aymd=`echo $aymdh | cut -c1-8`
  acyc=`echo $aymdh | cut -c9-10`
  echo $aymdh $aymd $acyc

  aymdh_m06=`$NDATE -6 $aymdh `
  aymd_m06=`echo $aymdh_m06 | cut -c1-8`
  acyc_m06=`echo $aymdh_m06 | cut -c9-10`
                                                           
  afile=$COMINgefs/gefs.${aymd}/${acyc}/atmos/pgrb2ap5/gec00.t${acyc}z.pgrb2a.0p50.f000
  afile_m06=$COMINgefs/gefs.${aymd_m06}/${acyc_m06}/atmos/pgrb2ap5/gec00.t${acyc_m06}z.pgrb2a.0p50.f006

  icnt=0
  while [ $icnt -le 30 ]; do
    if [ -s $afile -a -s $afile_m06 ]; then
      icnt=31 
    else
      echo " Warning !!!! There is no GEFS Analysis data for $afile or $afile_m06"
      sleep 1
      icnt=`expr $icnt + 1`
    fi
  done

###
# cfs analysi file entry
###

  rfile_in=$COMINcfs/cdas.${aymd}/cdas1.t${acyc}z.pgrbf00.grib2
  rfile_m06in=$COMINcfs/cdas.${aymd_m06}/cdas1.t${acyc_m06}z.pgrbf06.grib2     

  icnt=0
  while [ $icnt -le 30 ]; do
    if [ -s $rfile_in -a -s $rfile_m06in ]; then
      icnt=31 
    else
      echo " Warning !!!! There is no CFS Analysis data for $rfile_in or $rfile_m06in"
      sleep 1
      icnt=`expr $icnt + 1`
    fi
  done

  rfile=cdas1.t${acyc}z.pgrbf00.0p50.grib2
  rfile_m06=cdas1.t${acyc_m06}z.pgrbf06.0p50.grib2     
  grid2="0 6 0 0 0 0 0 0 720 361 0 0 90000000 0 48 -90000000 359500000 500000 500000 0"

  $COPYGB2 -g "$grid2" -x $rfile_in    $rfile
  $COPYGB2 -g "$grid2" -x $rfile_m06in $rfile_m06

###
#  get initialized bias between analyais and reanalysis entry
###

  pgbmdf=glbanl.t${cyc}z.pgrb2a.0p50_mdf000
  pgbmean=glbanl.t${cyc}z.pgrb2a.0p50_meandif

# if [ -s $COMINbias/gefs.$PDYm1/${cyc}/pgrb2ap5/$pgbmdf ]; then
#   cp $COMINbias/gefs.$PDYm1/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
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
  elif [ -s $COMINbias/gefs.$PDYm8/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm8/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  else
    echo " Cold Start for Bias Estimation between CDAS and GDAS Fcst. Hour " $nfhrs 
    cstart=1
  fi

###
#  output bias estimation between CDAS and GDAS            
###

  ofile=glbanl.t${cyc}z.pgrb2a.0p50_mdf000                        

  echo "&message"  >input.$nfhrs.$nens
  echo " icstart=${cstart}," >> input.$nfhrs.$nens
  echo " nens='$nens'," >>input.$nfhrs.$nens
  echo " dec_w=0.02," >> input.$nfhrs.$nens
  echo " odate=$odate," >>input.$nfhrs.$nens
  echo "/" >>input.$nfhrs.$nens

  ln -sf $pgbmean   fort.11
  ln -sf $afile     fort.12
  ln -sf $afile_m06 fort.13
  ln -sf $rfile     fort.14
  ln -sf $rfile_m06 fort.15
  ln -sf $ofile     fort.51

  startmsg
  $EXECgefs/$pgm <input.$nfhrs.$nens > $pgmout.$nfhrs.${nens} 2> errfile
  export err=$?;err_chk

 done
done
fi

###
#  calculate bias estimation between NCEP and CMC analysis: CMC anl - NCEP anl
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

  aymdh=$PDYm2$cyc
  aymd=`echo $aymdh | cut -c1-8`
  acyc=`echo $aymdh | cut -c9-10`

  aymdh_m06=`$NDATE -6 $aymdh `
  aymd_m06=`echo $aymdh_m06 | cut -c1-8`
  acyc_m06=`echo $aymdh_m06 | cut -c9-10`

  nfile=$COMINgefs/gefs.${aymd}/${acyc}/atmos/pgrb2ap5/gec00.t${acyc}z.pgrb2a.0p50.f000
  nfile_m06=$COMINgefs/gefs.${aymd_m06}/${acyc_m06}/atmos/pgrb2ap5/gec00.t${acyc_m06}z.pgrb2a.0p50.f006

  icnt=0
  while [ $icnt -le 30 ]; do
    if [ -s $nfile -a -s $nfile_m06 ]; then
      icnt=31 
    else
      echo " Warning !!!! There is no GEFS Analysis data for $nfile or $nfile_m06 "
      sleep 1
      icnt=`expr $icnt + 1`
    fi
  done

###
# CMC analysis file entry
###

  cfile=$DCOMINcmce/${aymd}/wgrbbul/cmcens_gb2/${aymd}${acyc}_CMC_naefs_latlon0p5x0p5_000_ana.grib2

  if [ $acyc -eq 00 ]; then
    cfile_m12=$COMINcmce/cmce.${PDYm3}/12/pgrb2ap5/cmc_geavg.t12z.pgrb2a.0p50.f012
  elif [ $acyc -eq 06 ]; then
    cfile_m12=$COMINcmce/cmce.${PDYm2}/00/pgrb2ap5/cmc_geavg.t00z.pgrb2a.0p50.f006
  elif [ $acyc -eq 12 ]; then
    cfile_m12=$COMINcmce/cmce.${PDYm2}/00/pgrb2ap5/cmc_geavg.t00z.pgrb2a.0p50.f012
  elif [ $acyc -eq 18 ]; then
    cfile_m12=$COMINcmce/cmce.${PDYm2}/12/pgrb2ap5/cmc_geavg.t12z.pgrb2a.0p50.f006
  fi

  icnt=0
  while [ $icnt -le 30 ]; do
    if [ -s $cfile -a -s $cfile_m12 ]; then
      icnt=31 
    else
      echo " Warning !!!! There is no CMC Analysis data for $cfile or $cfile_m12"
      sleep 1
      icnt=`expr $icnt + 1`
    fi
  done

###
#  get initialized bias between NCEP and CMC analysis 
###

  pgbmdf=ncepcmc_glbanl.t${cyc}z.pgrb2a.0p50_mdf000
  pgbmean=glbanl.t${cyc}z.pgrb2a.0p50_meandif

  if [ -s $COMINbias/gefs.$PDYm1/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm1/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/gefs.$PDYm2/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm2/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/gefs.$PDYm3/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm3/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/gefs.$PDYm4/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm4/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/gefs.$PDYm4/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm4/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/gefs.$PDYm5/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm5/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/gefs.$PDYm6/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm6/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  elif [ -s $COMINbias/gefs.$PDYm7/${cyc}/pgrb2ap5/$pgbmdf ]; then
    cp $COMINbias/gefs.$PDYm7/${cyc}/pgrb2ap5/$pgbmdf $pgbmean
  else
    echo " Cold Start for Bias Estimation between CMC and NCEP Analysis "
    cstart=1
  fi

###
#  output bias estimation between NCEP and CMC analysis   
###

  ofile=ncepcmc_glbanl.t${cyc}z.pgrb2a.0p50_mdf000                        

  echo "&message"  >input.$nfhrs.$nens
  echo " icstart=${cstart}," >> input.$nfhrs.$nens
  echo " nens='$nens'," >>input.$nfhrs.$nens
  echo " dec_w=0.30," >> input.$nfhrs.$nens
  echo " odate=$odate," >>input.$nfhrs.$nens
  echo "/" >>input.$nfhrs.$nens

  ln -sf $pgbmean       fort.11
  ln -sf $nfile         fort.12
  ln -sf $nfile_m06     fort.13
  ln -sf $cfile         fort.14
  ln -sf $cfile_m12     fort.15
  ln -sf $ofile         fort.51

  startmsg
  $EXECgefs/$pgm  <input.$nfhrs.$nens > $pgmout.$nfhrs.${nens} 2> ercfile
  export err=$?;err_chk

 done
done
fi

set +x
echo " "
echo "Leaving sub script gefs_bias_decay.sh"
echo " "
set -x

