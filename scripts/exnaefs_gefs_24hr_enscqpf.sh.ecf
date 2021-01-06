########################### EXENSCQPF ####################################
echo "------------------------------------------------"
echo "Ensemble Postprocessing - Accumulate for 24-hour Bias-corrected QPF"
echo "------------------------------------------------"
echo "History: Feb 2017 - First implementation of this new script."
echo "AUTHOR: Yan Luo (wx22lu)"
###########################################################################

###########################################################################
# This script generates the 24-hourly bias-corrected qpf & pqpf
###########################################################################

set +x
echo " "
echo " Entering sub script exnaefs_gefs_24hr_enscqpf.sh"
echo " job input forecast interval is: $HRINTER   "
echo " "
set -x

#################################
# set input parameters 
# PDY    : forecast initial time
# cyc    : initial cycle
# HRINTER: forecast hour interval
#################################

cd $DATA

hourlist="    006 012 018 024 030 036 042 048 054 060 066 072 078 084 090 096 \
          102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
          204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

outfile_prcp=enspost.t${cyc}z.prcp                      
                      
>$outfile_prcp

for nfhrs in $hourlist; do
    infile=$COMIN/prcp_bc_gb2/geprcp.t${cyc}z.pgrb2a.0p50.bc_06hf${nfhrs}                  
    $WGRIB2 -match ":APCP:" $infile  -append -grib  $outfile_prcp
done

# Specify the input/output file names for 24hr qpf:
pgm=gefs_enscqpf_24hr
pgmout=output

export CPGB=enspost.t${cyc}z.prcp
export CPGO=qpf

rm inputqpf

echo "&namin"                           >inputqpf
echo "icyc=$cyc"                       >>inputqpf
echo "hrinter=$HRINTER"                 >>inputqpf
echo "cpgb='$CPGB',cpge='$CPGO'"        >>inputqpf
echo "/"                                >>inputqpf

cat inputqpf

rm $CPGO

. prep_step
startmsg
$EXECgefs/$pgm  <inputqpf  >$pgmout
export err=$?;err_chk

  hourlist="                024 030 036 042 048 054 060 066 072 078 084 090 096 \
            102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
            204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
            306 312 318 324 330 336 342 348 354 360 366 372 378 384"
  var=prcp
  for nfhrs in $hourlist; do
    hb=`expr $nfhrs - 24`
    hd=`expr $nfhrs - 0`
    infile=qpf
    outfile=ge${var}.t${cyc}z.pgrb2a.0p50.bc_${HRINTER}hf$nfhrs
    $WGRIB2 -match ":${hb}-${hd} hour" $infile -grib $outfile
    if [ ! -s $outfile ]; then
      hb=`expr $hb / 24`
      hd=`expr $nfhrs / 24`
      $WGRIB2 -match ":${hb}-${hd} day" $infile -grib $outfile
    fi

    if [ ! -s $outfile ]; then
      echo "*********** Warning!!! Warning!!! ************"
      echo "**** There is empty file for $outfile ********"
    else
      cp $outfile $COMOUT/
      if [ "$SENDDBN" = "YES" ]; then
         # JY $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_24HR_CQPF_GB2 $job $COMOUT/${outfile}
         $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PCP_BC_GB2 $job $COMOUT/${outfile}
      fi
    fi
  done

# Specify the input/output file names for 24hr pqpf:

pgm=gefs_pgrb_enspqpf
pgmout=output

export CPGB=enspost.t${cyc}z.prcp
export CPGO=pqpf   

rm inputpqpf

echo "&namin"                           >inputpqpf
echo "icyc=$cyc"                       >>inputpqpf
echo "hrinter=$HRINTER"                 >>inputpqpf
echo "cpgb='$CPGB',cpge='$CPGO'"        >>inputpqpf
echo "/"                                >>inputpqpf

cat inputpqpf

rm $CPGO 

. prep_step
startmsg
$EXECgefs/$pgm  <inputpqpf  >$pgmout
export err=$?;err_chk

  hourlist="                024 030 036 042 048 054 060 066 072 078 084 090 096 \
            102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
            204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
            306 312 318 324 330 336 342 348 354 360 366 372 378 384"
  var=pqpf
  for nfhrs in $hourlist; do
    hb=`expr $nfhrs - 24`
    hd=`expr $nfhrs - 0`
    infile=pqpf
    outfile=ge${var}.t${cyc}z.pgrb2a.0p50.bc_${HRINTER}hf$nfhrs
    $WGRIB2 -match ":${hb}-${hd} hour" $infile -grib $outfile
    if [ ! -s $outfile ]; then
      hb=`expr $hb / 24`
      hd=`expr $nfhrs / 24`
      $WGRIB2 -match ":${hb}-${hd} day" $infile -grib $outfile
    fi
    if [ ! -s $outfile ]; then
      echo "*********** Warning!!! Warning!!! ************"
      echo "**** There is empty file for $outfile ********"
    else
      cp $outfile $COMOUT/
      if [ "$SENDDBN" = "YES" ]; then
         # JY $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_24HR_CPQPF_GB2 $job $COMOUT/${outfile}
         $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PQPF_BC_GB2 $job $COMOUT/${outfile}
      fi
    fi
  done

set +x
echo " "
echo "Leaving sub script exnaefs_gefs_24hr_enscqpf.sh"
echo " "
set -x


