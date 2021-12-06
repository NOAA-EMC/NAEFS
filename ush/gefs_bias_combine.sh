#!/bin/sh
#####################################################################
# Script:   gefs_bias_combine.sh  
# Abstract: Calculate Combined Bias From Decaying and Reforecast Bias
# History:  Aug. 2016 - First implementation of this new script
# AUTHOR:   Hong Guan
#####################################################################

set -x

mkdir -p $DATA/dir_combine

cd $DATA/dir_combine

##############################################
# define exec variable, and entry grib utility 
##############################################

export pgm=gefs_bias_combine
. prep_step

######################################################
# define if use the coefficient files in fix directory
######################################################
IFFIXCOEFF=YES

#############################
# calculate the combined bias
#############################

MD=`echo $PDY | cut -c5-8`

if [ "$IF_REFCSTWITH" = "YES" ]; then

  for nfhrs in $hourlist; do

###
#  set the index ( exist of bias estimation ) as default, 0
###

    cstart_ens=0
    cstart_rf=0

###
#  GEFS decaying bias estimation entry
###

    ibias_ens=geavg.t${cyc}z.pgrb2a.0p50_mef${nfhrs}

    CDATE=$PDY$cyc
    icnt=0

    while [ $icnt -le 16 ]; do
      PDYm=`echo $CDATE | cut -c1-8`
      if [ -s $COMINbias/gefs.$PDYm/${cyc}/pgrb2ap5/$ibias_ens ]; then
        cp $COMINbias/gefs.$PDYm/${cyc}/pgrb2ap5/$ibias_ens .
        icnt=17
      else
        icnt=`expr $icnt + 1`
      fi
      CDATE=`$NDATE -24 $CDATE`
    done

    if [ ! -s $ibias_ens ]; then
      echo " There is no Decaying Bias Estimation at " ${nfhrs}
      cstart_ens=1
    fi

###
##  GEFS reforecast bias estimation entry
####

    ibias_rf=rfbias_0p50.${MD}00.f${nfhrs}      

    if [ -s $DATA/dir_rfbias/$ibias_rf  ]; then
      cp $DATA/dir_rfbias/$ibias_rf .
    else
      echo " There is no Reforecast Bias at " ${nfhrs}
      cstart_rf=1
    fi

###
##  GEFS correlation coefficient data entry
####

    ifile_r2=geavg.t${cyc}z.pgrb2a.0p50_coefff${nfhrs}

    CDATE=$PDY$cyc
    icnt=0
    while [ $icnt -le 16 ]; do
      PDYm=`echo $CDATE | cut -c1-8`
      if [ -s $COMINbias/gefs.$PDYm/${cyc}/pgrb2ap5/$ifile_r2 ]; then
        cp $COMINbias/gefs.$PDYm/${cyc}/pgrb2ap5/$ifile_r2 .
        icnt=17
      else
        icnt=`expr $icnt + 1`
      fi
      CDATE=`$NDATE -24 $CDATE`
    done

    if [ ! -s $ifile_r2 ]; then
      if [ "$IFFIXCOEFF" = "YES" ]; then
        file=coeff.0p50_00
        cp $FIXgefs/$file .
        if [ $nfhrs -le 99 ]; then
          fhr=`expr $nfhrs - 0 `
        else
          fhr=$nfhrs
        fi
        >$ifile_r2
        $WGRIB2 -match ":${fhr} hour" $file -grib $ifile_r2
      else
        echo " There is no Correlation Coefficient at " ${nfhrs}
        cstart_rf=1
      fi
    fi

    echo "&message"                     >input.avg.$nfhrs
    echo " icstart_ens=${cstart_ens}," >> input.avg.$nfhrs
    echo " icstart_rf=${cstart_rf},"   >> input.avg.$nfhrs
    echo " nfhr=${nfhrs},"             >> input.avg.$nfhrs
    echo "/"                           >>input.avg.$nfhrs

###
#  GEFS bias combination output
###

    ofile=geavg.t${cyc}z.pgrb2a.0p50_mecomf${nfhrs}

    ln -sf $ibias_ens fort.11
    ln -sf $ifile_r2  fort.12
    ln -sf $ibias_rf  fort.13
    ln -sf $ofile     fort.51

    startmsg
    $EXECgefs/$pgm   <input.avg.$nfhrs     > $pgmout.mecom.$nfhrs 2> errfile
    export err=$?;err_chk

  done

elif [ "$IF_DECAYONLY" = "YES" ]; then

  for nfhrs in $hourlist; do
    ibias_ens=geavg.t${cyc}z.pgrb2a.0p50_mef${nfhrs}
    ofile=geavg.t${cyc}z.pgrb2a.0p50_mecomf${nfhrs}
    if [ -s $DATA/dir_decay/$ibias_ens ]; then
      cp $DATA/dir_decay/$ibias_ens $ofile
    else
      echo "No Decaying Bias at " ${nfhrs}
    fi
  done

elif [ "$IF_REFCSTONLY" = "YES" ]; then

  for nfhrs in $hourlist; do
    ibias_ens=rfbias_0p50.${MD}00.f${nfhrs}          
    ofile=geavg.t${cyc}z.pgrb2a.0p50_mecomf${nfhrs}
    if [ -s $DATA/dir_rfbias/$ibias_ens ]; then
      cp $DATA/dir_rfbias/$ibias_ens $ofile
    else
      echo "No Reforecast Bias at " ${nfhrs}
    fi
  done

fi

set +x
echo " "
echo "Leaving sub script gefs_bias_combine.sh"
echo " "
set -x
