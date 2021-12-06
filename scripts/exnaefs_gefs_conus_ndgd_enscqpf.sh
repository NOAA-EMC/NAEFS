#!/bin/sh
########################### EXENSDSCQPF ################################
echo "------------------------------------------------"
echo "Ensemble Postprocessing - Downscaling for Bias-corrected QPF   "
echo "------------------------------------------------"
echo "History: Feb 2017 - First implementation of this new script."
echo "History: Nov 2021 - Modify for WCOSS2 transition"
echo "AUTHOR: Yan Luo (wx22lu)"
#######################################################################

### To submit this job for T00Z, T06Z T12Z and T18Z, four cycles per day

### need pass the values of PDY, CYC, DATA, COMIN, and COMOUT

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
  export CDATE=`$NDATE +24 ${PDY}\18 `
else
  export CDATE=${PDY}${cyc}
fi

export YMDH=$CDATE  
export YMD=`echo $CDATE | cut -c1-8`
export YMDM1=`$NDATE -24 $YMDH | cut -c1-8`
export YY=`echo $CDATE | cut -c1-4`
export MM=`echo $CDATE | cut -c5-6`
export DD=`echo $CDATE | cut -c7-8`
export YMDHM12=`$NDATE -12 $YMDH `
export YMDHM24=`$NDATE +12 $YMDH `
export OBSYMDH=`$NDATE -12 $YMDH ` 
export OBSYMD=`$NDATE -24 $YMDH | cut -c1-8 `

cd $DATA

if [ $cyc -eq 18 ]; then
  OUTPATH=$COMOUT/gefs.$YMDM1/$cyc/ndgd_prcp_gb2
else 
  OUTPATH=$COMOUT/gefs.$YMD/$cyc/ndgd_prcp_gb2
fi

if [ $cyc -eq 18 ]; then
export YMDH=`$NDATE -24 $CDATE `
fi

###
### TO RUN DOWN-SCALING FOR 6-HOUR AND 24-HOUR FORECASTS, RESPECTIVELY 
###

for iacc in 06 24; do

if [ $iacc -eq 06 ]; then
hourlist="    006 012 018 024 030 036 042 048 054 060 066 072 078 084 090 096 \
          102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
          204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
          306 312 318 324 330 336 342 348 354 360 366 372 378 384"
fi

if [ $iacc -eq 24 ]; then
hourlist="                024 030 036 042 048 054 060 066 072 078 084 090 096 \
          102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
          204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
          306 312 318 324 330 336 342 348 354 360 366 372 378 384"
fi

mkdir -p $DATA/$cyc/${iacc}hr
cd  $DATA/$cyc/${iacc}hr

###
### STEP-ONE:
### DIRECTLY INTERPOLATE 0.5 DEGREE BIAS-CORRECTED PRODUCTS TO 2.5KM NDGD GRID
###
  
>ndgd.cmdfile

for nfhrs in $hourlist; do

 echo "$USHndgd/conus_ndgd_enswgrp.sh $nfhrs $iacc" >>ndgd.cmdfile

done      # for  nfhrs in $hourlist

cat ndgd.cmdfile
chmod 775 ndgd.cmdfile
export MP_CMDFILE=$DATA/$cyc/${iacc}hr/ndgd.cmdfile
#export MP_PGMMODEL=mpmd

#mpirun.lsf
${APRUNCQPF} ${MP_CMDFILE}

###
### STEP-TWO:
### TO RUN DOWNSCALING SCHEME
###

$USHndgd/conus_ndgd_enscqpf.sh $iacc

### two new productions
### 1). Down-scaled precipitation forecast ( gfs,ensembles and ctl )
### 2). Down-scaled ensemble based PQPF

  if [ "$SENDCOM" = "YES" ]
  then
  mkdir -p   $OUTPATH/

    for nfhrs in $hourlist; do
      infile_gb2=geprcp.t${cyc}z.ndgd2p5_conus.${iacc}hf$nfhrs.gb2
      outfile_gb2=geprcp.t${cyc}z.ndgd2p5_conus.${iacc}hf$nfhrs.gb2
    if [ ! -s $infile_gb2 ]; then
      echo "*********** Warning!!! Warning!!! ************"
      echo "**** There is empty file for $outfile_gb2 ********"
    else
        cp ${infile_gb2} $OUTPATH/${outfile_gb2}
        if [ "$SENDDBN" = "YES" ]; then
           $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PCP_BC_GB2 $job $OUTPATH/${outfile_gb2}
        fi
    fi
      infile_gb2=gepqpf.t${cyc}z.ndgd2p5_conus.${iacc}hf$nfhrs.gb2
      outfile_gb2=gepqpf.t${cyc}z.ndgd2p5_conus.${iacc}hf$nfhrs.gb2
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

  fi     # for "if [ "$SENDCOM" = "YES" ]"

done    # for iacc in 06 24

#####################################################################
# GOOD RUN
set +x
echo "**************JOB ENS_NDGD_DSCQPF COMPLETED NORMALLY"
echo "**************JOB ENS_NDGD_DSCQPF COMPLETED NORMALLY"
set -x
#####################################################################

msg="HAS COMPLETED NORMALLY!"
postmsg "$jlogfile" "$msg"

exit 0
############## END OF SCRIPT #######################
