#!/bin/sh
#################################################################################
# CMC Ensemble Postprocessing, Convert CMC Bias Corrected Ens from Grib2 to Grib1 
# History: Oct 2011 - First implementation of this new script
#            Mar 2017 - updated for post-processing grib2 data directly
# AUTHOR: Bo Cui  (wx20cb)
#################################################################################

export PS4='${PMI_FORK_RANK}: $SECONDS + '
set -x

#####################################

export ENSANOMALY=$USHcmce/cmce_climate_anomaly.sh
export ENSWEIGHTS=$USHcmce/cmce_weights.sh
export ENSAVGSPR=$USHcmce/cmcensbc_post_avgspr.sh

#####################################
# START TO DUMP DATA FOR $cycle CYCLE
#####################################

msg="Starting postprocessing for $cycle Ensemble memebers"
postmsg "$jlogfile" "$msg"

RUN="cmcens"

########################################################
# Begin Processing Ensemble Forecast Data at 00z and 12z
########################################################

export hourlist=" 000 003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 \
                  051 054 057 060 063 066 069 072 075 078 081 084 087 090 093 096 099 \
                  102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 \
                  153 156 159 162 165 168 171 174 177 180 183 186 189 192 198 204 \
                  210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
                  306 312 318 324 330 336 342 348 354 360 366 372 378 384"

export memberlist="p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 \
                   p11 p12 p13 p14 p15 p16 p17 p18 p19 p20 c00"

if [ $cyc -eq 00 -o $cyc -eq 12 ]; then

##########################################
# Step 0: check if all files are available
##########################################

  icnt=0
  while [ $icnt -le 30 ]; do
    ifile=0
    tfile=0
    for nfhrs in $hourlist; do
      for mem in $memberlist; do
        (( tfile = tfile + 1 ))
        cmcmem=`echo $mem | cut -c2-3`
        PGBF=$DCOM_IN/${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P${nfhrs}_0${cmcmem}.grib2
        if [ -s $PGBF ]; then
          (( ifile = ifile + 1 ))
        fi
      done
    done
    if [ $tfile -eq $ifile ]; then
      icnt=31
    else
      sleep 30
      icnt=`expr $icnt + 1`
    fi
  done

  icnt=0
  for nfhrs in $hourlist; do
    for mem in $memberlist; do
      cmcmem=`echo $mem | cut -c2-3`
      PGBF=$DCOM_IN/${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P${nfhrs}_0${cmcmem}.grib2
      if [ ! -s $PGBF ]; then
        echo "File $PGBF is missing "
        icnt=`expr $icnt + 1`
      fi
    done
  done

  if [ $icnt -ge 1 ]; then
    echo "ERROR: totally $icnt CMC files missing, please wait until they are available and rerun this job"
    err_exit
  fi

#############################
#  calculate anomaly forecast                  
#############################

for nfhrs in $hourlist; do
  mkdir -p $DATA/group.$nfhrs      
done

for mem in $memberlist; do
  if [ -s poescript_an.$mem ]; then  rm poescript_an.$mem; fi
  cmcmem=`echo $mem | cut -c2-3`
  for nfhrs in $hourlist; do
    PGBF=$DCOM_IN/${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P${nfhrs}_0${cmcmem}.grib2
    if [ -s $PGBF ]; then
      echo "$ENSANOMALY $PDY$cyc $nfhrs $cmcmem $DATA/group.$nfhrs" >>$DATA/poescript_an.$mem
    else
      echo "echo "no file of" $PGBF "                               >>$DATA/poescript_an.$mem
    fi
  done
  chmod +x poescript_an.$mem
  $APRUN poescript_an.$mem
done

if [ "$SENDCOM" = "YES" ]; then
  for nfhrs in $hourlist; do
    for mem in $memberlist; do
      PGBO=cmc_ge${mem}.t${cyc}z.pgrb2a.0p50_anf${nfhrs} 
      mv $DATA/group.$nfhrs/$PGBO $COMOUTAN_GB2/
    done
  done
fi

#####################################
#  calculate ensemble mean and spread
#####################################

$ENSAVGSPR

###############################################################
#  release the NAEFS products generation job jnaefs_prob_avgspr
###############################################################
ecflow_client --event release_naefs_avgspr

############################################
#  calculate weight for each ensemble member
############################################

for mem in $memberlist; do
  if [ -s poescript_wt.${mem} ]; then  rm poescript_wt.${mem}; fi
  cmcmem=`echo $mem | cut -c2-3`
  for nfhrs in $hourlist; do
    PGBF=$DCOM_IN/${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P${nfhrs}_0${cmcmem}.grib2
    if [ -s $PGBF ]; then
      echo "$ENSWEIGHTS $PDY$cyc $nfhrs $cmcmem $DATA/group.$nfhrs" >>$DATA/poescript_wt.${mem}
    else
      echo "echo "no file of" $PGBF "                               >>$DATA/poescript_wt.${mem}
    fi
  done
  chmod +x poescript_wt.${mem}
  $APRUN poescript_wt.${mem}
done

if [ "$SENDCOM" = "YES" ]; then
  for nfhrs in $hourlist; do
    for mem in $memberlist; do
      PGBO=cmc_ge${mem}.t${cyc}z.pgrb2a.0p50_wtf${nfhrs} 
      mv $DATA/group.$nfhrs/$PGBO $COMOUTWT_GB2/
    done
  done
fi

cat $DATA/group.006/$pgmout.006.01_an
cat $DATA/group.006/$pgmout.006.01_wt
cat $pgmout.006_avgspr

cat $DATA/group.360/$pgmout.360.12_an
cat $DATA/group.360/$pgmout.360.12_wt
cat $pgmout.360_avgspr

#######################################################
# End Processing Ensemble Forecast Data at 00z and 12z
#######################################################
fi

msg="HAS COMPLETED NORMALLY!"
postmsg "$jlogfile" "$msg"
exit 0

