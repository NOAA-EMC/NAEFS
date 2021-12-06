#!/bin/sh
###############################################################################################

echo "---------------------------------------------------------"
echo "Calculate GEFS anomaly forecast and EFI for 24-hr accmulated precipitation"
echo "---------------------------------------------------------"
echo "History: March 2017 - First implementation of this new script"
echo "AUTHOR: Hong Guan (Hong.Guan)"
####################################################################################################

### To submit this job for T00Z, T06Z T12Z and T18Z, four cycles per day

set -x

################################################################
# define exec variable, and entry grib utility 
################################################################

export CDATE=${PDY}${cyc}
export YMDH=$CDATE
export YMDM1=`$NDATE -24 $YMDH | cut -c1-8`

export ENSANOMALY=$HOMEgefs/ush/gefs_anfefi_acpr.sh

hourlist="                024 030 036 042 048 054 060 066 072 078 084 090 096 \
          102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
          204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

if [ $cyc -eq 18 ]; then
export YMDH=${YMDM1}\18
fi

grid="0 6 0 0 0 0 0 0 720 361 0 0 90000000 0 48 -90000000 359500000 500000 500000 0"

  for nfhrs in $hourlist
  do

    export  JDATE=`$NDATE +$nfhrs $YMDH`
    export  MMDD=`echo $JDATE | cut -c5-8`

    ln -fs ${FIXgefs}/gamma1_24hr_2004${MMDD} gam1.dat
    ln -fs ${FIXgefs}/gamma2_24hr_2004${MMDD} gam2.dat
    $COPYGB2 -g "$grid" -x  gam1.dat  gamma1.dat
    $COPYGB2 -g "$grid" -x  gam2.dat  gamma2.dat

    echo "&message"  >input.$nfhrs
    echo " nfhr=${nfhrs}," >> input.$nfhrs
    echo "/" >>input.$nfhrs

        export COMIN_fcst=${COMIN}/prcp_bc_gb2/geprcp.t${cyc}z.pgrb2a.0p50.bc_24hf${nfhrs}

        $ENSANOMALY $CDATE $nfhrs

    if [ "$SENDCOM" = "YES" ]; then
       outfile=geprcp.t${cyc}z.pgrb2a.0p50.anvf$nfhrs
       if [ -s $outfile ]; then
          mv $outfile $COMOUTANFEFI_p5/
          $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PCP_BC_GB2 $job $COMOUTANFEFI_p5/${outfile}
       fi
       outfile=geprcp.t${cyc}z.pgrb2a.0p50.efif$nfhrs
       if [ -s $outfile ]; then
          mv $outfile $COMOUTANFEFI_p5/
          $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PCP_BC_GB2 $job $COMOUTANFEFI_p5/${outfile}
       fi
    fi
  done

msg="HAS COMPLETED NORMALLY!"
postmsg "$jlogfile" "$msg"

exit 0
