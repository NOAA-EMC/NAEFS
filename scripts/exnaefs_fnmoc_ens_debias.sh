#!/bin/sh
#################################### FORECAST DEBIAS ###############################################
echo "------------------------------------------"
echo "Bias Correct FNMOC Global Ensemble Forecast "
echo "------------------------------------------"
echo "History: Oct 2010 - First implementation of this new script"
echo "AUTHOR: Bo Cui  (wx20cb)"
####################################################################################################

### To submit this job for T00Z and T12Z, twice per day
### need pass the values of PDY, CYC, DATA, COMIN, COM, COMOUTBC, COMOUTAN and COMOUTWT

################################################################
# define exec variable, and entry grib utility 
################################################################
set -x

export hourlist=$1
export workdir=$2

if [ -f $workdir ]; then
  mkdir -p $workdir
fi

cd $workdir

export ENSANOMALY=$USHfnmoc/fnmocens_climate_anomaly.sh
export ENSWEIGHTS=$USHfnmoc/fnmocens_weights.sh

export pgm=fnmocens_debias
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

##########################################################################
# bias correct NCEP global ensemble for each forecast time and each member
##########################################################################

#hourlist="     06  12  18  24  30  36  42  48  54  60  66  72  78  84  90  96 \
#          102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
#          204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
#          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

memberlist="p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20 c00"

wallcnt=0
for nens in $memberlist
do

  for nfhrs in $hourlist
  do

###
#  check FNMOC bias corrected forecast file
###

    fensmem=`echo $nens | cut -c2-3`

    if [ $nfhrs -le 99 ];then
      ifile_in=$COMINBC/ENSEMBLE.MET.fcst_bc0${fensmem}.0${nfhrs}.${PDY}${cyc}
    else
      ifile_in=$COMINBC/ENSEMBLE.MET.fcst_bc0${fensmem}.${nfhrs}.${PDY}${cyc}
    fi

    ofile=fnmoc_ge${nens}.t${cyc}z.pgrb2a_bcf${nfhrs}

    icnt=0
    while [ $icnt -le 30 ]; do
    start_time=$(date +%s)
      if [ -s $ifile_in ]; then

        ln -sf $ifile_in $ofile
        export MEMLIST=$nens
        $ENSANOMALY $PDY$cyc $nfhrs

        $ENSWEIGHTS $PDY$cyc $nfhrs

        icnt=31

#### sendcom  bias corrected forecast

        if [ "$SENDCOM" = "YES" ]; then

          if [ -s fnmoc_ge${nens}.t${cyc}z.pgrb2a_anf$nfhrs ]; then
            mv fnmoc_ge${nens}.t${cyc}z.pgrb2a_anf$nfhrs $COMOUTAN/
          fi

          if [ -s fnmoc_ge${nens}.t${cyc}z.pgrb2a_wtf$nfhrs ]; then
            mv fnmoc_ge${nens}.t${cyc}z.pgrb2a_wtf$nfhrs $COMOUTWT/
          fi
        fi

      else

        sleep 10
        icnt=`expr $icnt + 1`
	echo $icnt
      fi
    end_time=$(date +%s)
    elapsed_time=$(( end_time - start_time ))
    wallcnt=$(( wallcnt + elapsed_time ))
    echo "wallcnt=${wallcnt}"
    if [ ${wallcnt} -ge 3540 ]; then
      echo "jnaefs_fnmoc_ens_debias_${cyc} is about to exceed wall clock for data of opportunity"   >> ${DATA}/wallkill
      echo "allow job to complete and send email"                                                   >> ${DATA}/wallkill
      exit
    fi
    done

  done
done


msg="HAS COMPLETED NORMALLY!"
postmsg "$jlogfile" "$msg"

exit 0
