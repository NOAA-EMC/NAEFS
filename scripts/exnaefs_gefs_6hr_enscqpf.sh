#!/bin/sh
########################### EXENSCQPF ################################
echo "------------------------------------------------"
echo "Ensemble Postprocessing - Calibration for QPF   "
echo "------------------------------------------------"
echo "History: Feb 2004 - First implementation of this new script."
echo "History: Feb 2006 - 2nd   implementation of this new script."
echo "AUTHOR: Yuejian Zhu (wx20yz)"
echo "History: Dec 2011 - Upgrade to 1 degree and 6 hourly"
echo "History: Dec 2013 - Change I/O from GRIB1 to GRIB2"
echo "History: Dec 2016 - Upgrade to 0.5 degree and 6 hourly"
echo "History: Nov 2021 - Modify for WCOSS2 transition"
echo "AUTHOR: Yan Luo (wx22lu)"
#######################################################################

### To submit this job for T00Z, T06Z T12Z and T18Z, four cycles per day

### need pass the values of PDY, CYC, DATA, COMINccpa, COMIN, and COMOUT

export PS4='${PMI_FORK_RANK}: $SECONDS + '
set -x

### 
###       NOTES for data conversion
###    1. CDATE  ---> initial day, current day at T00Z
###    2. OBSYMD ---> previous day, end of ymd and T12Z
###    3. YMDH   ---> current day at T00Z
###

export cycle=t${cyc}z
echo " cyc = $cyc "
echo " This job is handling ${cyc}Z cycle "
if [ $cyc -eq 18 ]; then
  export CDATE=`$NDATE +24 ${PDY}\00 `
else 
  export CDATE=${PDY}\00
fi
export YMDH=$CDATE  
export YMD=`echo $CDATE | cut -c1-8`
export YY=`echo $CDATE | cut -c1-4`
export MM=`echo $CDATE | cut -c5-6`
export DD=`echo $CDATE | cut -c7-8`
export YMDHM12=`$NDATE -12 $YMDH `
export YMDHM24=`$NDATE +12 $YMDH `
export OBSYMDH=`$NDATE -12 $YMDH ` 
export OBSYMD=`$NDATE -24 $YMDH | cut -c1-8 `

######################################################
# define the days for searching bias estimation backup
######################################################
####
export YMDM1=`$NDATE -24 $YMDH | cut -c1-8`
export YMDM2=`$NDATE -48 $YMDH | cut -c1-8`
export YMDM3=`$NDATE -72 $YMDH | cut -c1-8` 
export YMDM4=`$NDATE -96 $YMDH | cut -c1-8`
export YMDM5=`$NDATE -120 $YMDH | cut -c1-8`
export YMDM6=`$NDATE -144 $YMDH | cut -c1-8`
export YMDM7=`$NDATE -168 $YMDH | cut -c1-8`
export YMDM8=`$NDATE -192 $YMDH | cut -c1-8`
export YMDM9=`$NDATE -216 $YMDH | cut -c1-8`
export YMDM10=`$NDATE -240 $YMDH | cut -c1-8`
export YMDM11=`$NDATE -264 $YMDH | cut -c1-8`
export YMDM12=`$NDATE -288 $YMDH | cut -c1-8`
export YMDM13=`$NDATE -312 $YMDH | cut -c1-8`
export YMDM14=`$NDATE -336 $YMDH | cut -c1-8`
export YMDM15=`$NDATE -360 $YMDH | cut -c1-8`
export YMDM16=`$NDATE -384 $YMDH | cut -c1-8`
export YMDM17=`$NDATE -408 $YMDH | cut -c1-8`
export YMDM18=`$NDATE -432 $YMDH | cut -c1-8`

cd $DATA
mkdir -p $DATA/$cyc 
cd $DATA/$cyc
#$utilscript/setup.sh

###
### PRE-STEP ONE:
### Get OBS preciptation data 

ESCAPE=NO
for hh in 06 12 18 24
do 
 case $hh in 
  06) tt=18;oymd=$YMDM2;; 
  12) tt=00;oymd=$YMDM1;;
  18) tt=06;oymd=$YMDM1;;
  24) tt=12;oymd=$YMDM1
 esac

grid="0 6 0 0 0 0 0 0 720 361 0 0 90000000 0 48 -90000000 359500000 500000 500000 0"
if [ -s $COMINccpa/ccpa.$oymd/$tt/ccpa.t${tt}z.06h.hrap.conus.gb2 ]; then
  echo " $COMINccpa/ccpa.$oymd/$tt/ccpa.t${tt}z.06h.hrap.conus.gb2 is available "
  inhrap=$COMINccpa/ccpa.$oymd/$tt/ccpa.t${tt}z.06h.hrap.conus.gb2
  out0p5=$DATA/$cyc/ccpa.t${tt}z.06h.0p5.conus.gb2
  $COPYGB2 -g "$grid" -i3 -x  $inhrap $out0p5
else 
  echo "WARNING:$COMINccpa/ccpa.$oymd/$tt/ccpa.t${tt}z.06h.hrap.conus.gb2 is missing!!!"
  ESCAPE=YES
fi
done

###
### PRE-STEP TWO:
###  Check job status 

if [ $cyc -eq 18 ]; then
  OUTPATH=$COMOUT/gefs.$YMDM1/$cyc/prcp_bc_gb2
else 
  OUTPATH=$COMOUT/gefs.$YMD/$cyc/prcp_bc_gb2
fi

############################################################################
# Training data accumulated up to 50 day period for later decaying averaging
############################################################################
if [ -s $COMOUT/gefs.$YMDM1/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat ]; then
  cp $COMOUT/gefs.$YMDM1/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat \
     $DATA/$cyc/STAT_RM_BIAS_gfs.dat
elif [ -s $COMOUT/gefs.$YMDM2/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat ]; then
  cp $COMOUT/gefs.$YMDM2/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat \
     $DATA/$cyc/STAT_RM_BIAS_gfs.dat
elif [ -s $COMOUT/gefs.$YMDM3/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat ]; then
  cp $COMOUT/gefs.$YMDM3/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat \
     $DATA/$cyc/STAT_RM_BIAS_gfs.dat
elif [ -s $COMOUT/gefs.$YMDM4/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat ]; then
  cp $COMOUT/gefs.$YMDM4/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat \
     $DATA/$cyc/STAT_RM_BIAS_gfs.dat
elif [ -s $COMOUT/gefs.$YMDM5/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat ]; then
  cp $COMOUT/gefs.$YMDM5/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat \
     $DATA/$cyc/STAT_RM_BIAS_gfs.dat
elif [ -s $COMOUT/gefs.$YMDM6/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat ]; then
  cp $COMOUT/gefs.$YMDM6/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat \
     $DATA/$cyc/STAT_RM_BIAS_gfs.dat
elif [ -s $COMOUT/gefs.$YMDM7/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat ]; then
  cp $COMOUT/gefs.$YMDM7/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat \
     $DATA/$cyc/STAT_RM_BIAS_gfs.dat
elif [ -s $COMOUT/gefs.$YMDM8/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat ]; then
  cp $COMOUT/gefs.$YMDM8/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat \
     $DATA/$cyc/STAT_RM_BIAS_gfs.dat
elif [ -s $COMOUT/gefs.$YMDM9/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat ]; then
  cp $COMOUT/gefs.$YMDM9/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat \
     $DATA/$cyc/STAT_RM_BIAS_gfs.dat
elif [ -s $COMOUT/gefs.$YMDM10/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat ]; then
  cp $COMOUT/gefs.$YMDM10/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat \
     $DATA/$cyc/STAT_RM_BIAS_gfs.dat
elif [ -s $COMOUT/gefs.$YMDM11/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat ]; then
  cp $COMOUT/gefs.$YMDM11/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat \
     $DATA/$cyc/STAT_RM_BIAS_gfs.dat
elif [ -s $COMOUT/gefs.$YMDM12/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat ]; then
  cp $COMOUT/gefs.$YMDM12/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat \
     $DATA/$cyc/STAT_RM_BIAS_gfs.dat
elif [ -s $COMOUT/gefs.$YMDM13/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat ]; then
  cp $COMOUT/gefs.$YMDM13/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat \
     $DATA/$cyc/STAT_RM_BIAS_gfs.dat
elif [ -s $COMOUT/gefs.$YMDM14/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat ]; then
  cp $COMOUT/gefs.$YMDM14/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat \
     $DATA/$cyc/STAT_RM_BIAS_gfs.dat
elif [ -s $COMOUT/gefs.$YMDM15/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat ]; then
  cp $COMOUT/gefs.$YMDM15/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat \
     $DATA/$cyc/STAT_RM_BIAS_gfs.dat
elif [ -s $COMOUT/gefs.$YMDM16/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat ]; then
  cp $COMOUT/gefs.$YMDM16/$cyc/prcp_bc_gb2/STAT_RM_BIAS_gfs.dat \
     $DATA/$cyc/STAT_RM_BIAS_gfs.dat
elif [ -s ${FIXgefs}/STAT_RM_BIAS_gfs_M${MM}_t${cyc}z.dat ]; then
  cp ${FIXgefs}/STAT_RM_BIAS_gfs_M${MM}_t${cyc}z.dat \
     $DATA/$cyc/STAT_RM_BIAS_gfs.dat
else
  echo "FATAL ERROR: Input gfs STAT bias file not available"
  export err=1; err_chk
fi

if [ -s $COMOUT/gefs.$YMDM1/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat ]; then
  cp $COMOUT/gefs.$YMDM1/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat \
     $DATA/$cyc/STAT_RM_BIAS_ctl.dat
elif [ -s $COMOUT/gefs.$YMDM2/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat ]; then
  cp $COMOUT/gefs.$YMDM2/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat \
     $DATA/$cyc/STAT_RM_BIAS_ctl.dat
elif [ -s $COMOUT/gefs.$YMDM3/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat ]; then
  cp $COMOUT/gefs.$YMDM3/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat \
     $DATA/$cyc/STAT_RM_BIAS_ctl.dat
elif [ -s $COMOUT/gefs.$YMDM4/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat ]; then
  cp $COMOUT/gefs.$YMDM4/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat \
     $DATA/$cyc/STAT_RM_BIAS_ctl.dat
elif [ -s $COMOUT/gefs.$YMDM5/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat ]; then
  cp $COMOUT/gefs.$YMDM5/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat \
     $DATA/$cyc/STAT_RM_BIAS_ctl.dat
elif [ -s $COMOUT/gefs.$YMDM6/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat ]; then
  cp $COMOUT/gefs.$YMDM6/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat \
     $DATA/$cyc/STAT_RM_BIAS_ctl.dat
elif [ -s $COMOUT/gefs.$YMDM7/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat ]; then
  cp $COMOUT/gefs.$YMDM7/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat \
     $DATA/$cyc/STAT_RM_BIAS_ctl.dat
elif [ -s $COMOUT/gefs.$YMDM8/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat ]; then
  cp $COMOUT/gefs.$YMDM8/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat \
     $DATA/$cyc/STAT_RM_BIAS_ctl.dat
elif [ -s $COMOUT/gefs.$YMDM9/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat ]; then
  cp $COMOUT/gefs.$YMDM9/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat \
     $DATA/$cyc/STAT_RM_BIAS_ctl.dat
elif [ -s $COMOUT/gefs.$YMDM10/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat ]; then
  cp $COMOUT/gefs.$YMDM10/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat \
     $DATA/$cyc/STAT_RM_BIAS_ctl.dat
elif [ -s $COMOUT/gefs.$YMDM11/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat ]; then
  cp $COMOUT/gefs.$YMDM11/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat \
     $DATA/$cyc/STAT_RM_BIAS_ctl.dat
elif [ -s $COMOUT/gefs.$YMDM12/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat ]; then
  cp $COMOUT/gefs.$YMDM12/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat \
     $DATA/$cyc/STAT_RM_BIAS_ctl.dat
elif [ -s $COMOUT/gefs.$YMDM13/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat ]; then
  cp $COMOUT/gefs.$YMDM13/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat \
     $DATA/$cyc/STAT_RM_BIAS_ctl.dat
elif [ -s $COMOUT/gefs.$YMDM14/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat ]; then
  cp $COMOUT/gefs.$YMDM14/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat \
     $DATA/$cyc/STAT_RM_BIAS_ctl.dat
elif [ -s $COMOUT/gefs.$YMDM15/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat ]; then
  cp $COMOUT/gefs.$YMDM15/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat \
     $DATA/$cyc/STAT_RM_BIAS_ctl.dat
elif [ -s $COMOUT/gefs.$YMDM16/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat ]; then
  cp $COMOUT/gefs.$YMDM16/$cyc/prcp_bc_gb2/STAT_RM_BIAS_ctl.dat \
     $DATA/$cyc/STAT_RM_BIAS_ctl.dat
elif [ -s ${FIXgefs}/STAT_RM_BIAS_ctl_M${MM}_t${cyc}z.dat ]; then
  cp ${FIXgefs}/STAT_RM_BIAS_ctl_M${MM}_t${cyc}z.dat \
     $DATA/$cyc/STAT_RM_BIAS_ctl.dat
else
  echo "FATAL ERROR: Input ctl STAT bias file not available"
  export err=1; err_chk
fi

###
### PRE-STEP THREE:
### Check OBS preciptation data 
###

if [ $ESCAPE == NO ]; then
  echo " ***** Perform precipitation verification    *****"
  $USHgefs/gefs_enspvrfy.sh      >enspvrfy_output
else
  echo " ***** Observation data is not available *****"
  echo " ***** Skip precipitation verify step    *****"
fi

export hourlist="006 012 018 024 030 036 042 048 054 060 066 072 078 084 090 096 \
                 102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
                 204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
                 306 312 318 324 330 336 342 348 354 360 366 372 378 384"

>wgrp.cmdfile

for nfhrs in $hourlist; do

 echo "$USHgefs/gefs_enswgrp.sh $nfhrs" >>wgrp.cmdfile

done      # for  nfhrs in $hourlist

cat wgrp.cmdfile
chmod 775 wgrp.cmdfile
export MP_CMDFILE=$DATA/$cyc/wgrp.cmdfile
#export MP_PGMMODEL=mpmd

#mpirun.lsf
${APRUNCQPF} ${MP_CMDFILE}

###
### STEP-ONE:
### TO CREAT NEW STATISTC FOR GFS AND ENSEMBLE CTL                  
### USING OLD ONE INSTEAD OF IF NO PRECIP. OBS OR FORECASTS
###

$USHgefs/gefs_enssrbias.sh gfs  
$USHgefs/gefs_enssrbias.sh ctl 

###
### STEP-TWO:
### TO RUN CALIBRATION SCHEME
###

$USHgefs/gefs_enscqpf.sh

### two new productions
### 1). Bias-calibrated precipitation forecast ( gfs,ensembles and ctl )
### 2). Bias-calibrated ensemble based PQPF 

  if [ "$SENDCOM" = "YES" ]
  then
  mkdir -p   $OUTPATH/

    for nfhrs in $hourlist; do
      infile_gb2=geprcp.t${cyc}z.pgrb2a.0p50.bc_f$nfhrs
      outfile_gb2=geprcp.t${cyc}z.pgrb2a.0p50.bc_06hf$nfhrs
    if [ ! -s $infile_gb2 ]; then
      echo "*********** Warning!!! Warning!!! ************"
      echo "**** There is empty file for $outfile_gb2 ********"
    else
        cp ${infile_gb2} $OUTPATH/${outfile_gb2}
        if [ "$SENDDBN" = "YES" ]; then
           $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PCP_BC_GB2 $job $OUTPATH/${outfile_gb2}
        fi
    fi

      infile_gb2=gepqpf.t${cyc}z.pgrb2a.0p50.bc_f$nfhrs
      outfile_gb2=gepqpf.t${cyc}z.pgrb2a.0p50.bc_06hf$nfhrs
    if [ ! -s $infile_gb2 ]; then
      echo "*********** Warning!!! Warning!!! ************"
      echo "**** There is empty file for $outfile_gb2 ********"
    else
        cp ${infile_gb2} $OUTPATH/$outfile_gb2 
        if [ "$SENDDBN" = "YES" ]; then
           $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PQPF_BC_GB2 $job $OUTPATH/${outfile_gb2}
        fi
    fi

   done

###
### Save verification results for next calibration
###
   cp STAT_RM_BIAS_gfs.$YMD     $OUTPATH/STAT_RM_BIAS_gfs.dat
   cp STAT_RM_BIAS_ctl.$YMD     $OUTPATH/STAT_RM_BIAS_ctl.dat
   cp STAT_RM_BIAS_gfs.txt      $OUTPATH/STAT_RM_BIAS_gfs.txt
   cp STAT_RM_BIAS_ctl.txt      $OUTPATH/STAT_RM_BIAS_ctl.txt
   cp rain_gfs.$YMDM1           $OUTPATH/rain_vrfy_gfs.dat
   cp rain_ctl.$YMDM1           $OUTPATH/rain_vrfy_ctl.dat

  fi     # for "if [ "$SENDCOM" = "YES" ]"

#####################################################################
# GOOD RUN
set +x
echo "**************JOB ENS_PGRB_CQPF COMPLETED NORMALLY"
echo "**************JOB ENS_PGRB_CQPF COMPLETED NORMALLY"
set -x
#####################################################################

msg="HAS COMPLETED NORMALLY!"
postmsg "$jlogfile" "$msg"

exit 0
############## END OF SCRIPT #######################
