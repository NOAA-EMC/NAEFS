#!/bin/sh
###########################################################################
# This script generates the 6-hourly (12 or 24 hr) pqpf pqif pqrf pqff pqsf
###########################################################################

set +x
echo " "
echo " Entering sub script exgefs_pgrb_enspqpf.sh"
echo " job input forecast interval is: $HRINTER   "
echo " "
set -x

#################################
# set input parameters 
# PDY    : forecast initial time
# cyc    : initial cycle
# HRINTER: forecast hour interval
#################################

pgm=gefs_pgrb_enspqpf
pgmout=output

cd $DATA

hourlist="    006 012 018 024 030 036 042 048 054 060 066 072 078 084 090 096 \
          102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
          204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

memberlist="c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"

outfile_prcp=enspost.t${cyc}z.prcp                      
outfile_rain=enspost.t${cyc}z.rain                      
outfile_frzr=enspost.t${cyc}z.frzr                      
outfile_icep=enspost.t${cyc}z.icep                      
outfile_snow=enspost.t${cyc}z.snow                      

>$outfile_prcp
if [ "$HRINTER" = "6" ]; then
  >$outfile_rain
  >$outfile_frzr
  >$outfile_icep
  >$outfile_snow
fi

for nfhrs in $hourlist; do
  for nens in $memberlist; do
    infile=$COMINgefs/ge${nens}.t${cyc}z.pgrb2a.0p50.f${nfhrs}                  
    $WGRIB2 -match ":APCP:" $infile  -append -grib  $outfile_prcp
    if [ "$HRINTER" = "6" ]; then
      $WGRIB2 -match ":CRAIN:" $infile  -append -grib  $outfile_rain
      $WGRIB2 -match ":CFRZR:" $infile  -append -grib  $outfile_frzr
      $WGRIB2 -match ":CICEP:" $infile  -append -grib  $outfile_icep
      $WGRIB2 -match ":CSNOW:" $infile  -append -grib  $outfile_snow
    fi
  done
done

# Specify the input/output file names:

export CPGB=enspost.t${cyc}z.prcp
export CPGO=pqpf   

export CRAIN=enspost.t${cyc}z.rain
export CRAINO=pqrf

export CFRZR=enspost.t${cyc}z.frzr
export CFRZRO=pqff

export CICEP=enspost.t${cyc}z.icep
export CICEPO=pqif 

export CSNOW=enspost.t${cyc}z.snow
export CSNOWO=pqsf  

rm inputpqpf

echo "&namin"                           >inputpqpf
echo "icyc=$cyc"                       >>inputpqpf
echo "hrinter=$HRINTER"                 >>inputpqpf
echo "cpgb='$CPGB',cpge='$CPGO'"        >>inputpqpf
echo "crain='$CRAIN',craino='$CRAINO'"  >>inputpqpf
echo "cfrzr='$CFRZR',cfrzro='$CFRZRO'"  >>inputpqpf
echo "cicep='$CICEP',cicepo='$CICEPO'"  >>inputpqpf
echo "csnow='$CSNOW',csnowo='$CSNOWO'"  >>inputpqpf
echo "/"                                >>inputpqpf

cat inputpqpf

rm $CPGO $CRAINO $CFRZRO $CICEPO $CSNOWO

. prep_step
startmsg
$EXECgefs/$pgm  <inputpqpf  >$pgmout
export err=$?;err_chk

if [ "$HRINTER" = "6" ]; then
  hourlist="    006 012 018 024 030 036 042 048 054 060 066 072 078 084 090 096 \
            102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
            204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
            306 312 318 324 330 336 342 348 354 360 366 372 378 384"

  for var in pqpf pqrf pqsf pqif pqff; do
    for nfhrs in $hourlist; do
      hb=`expr $nfhrs - 6`
      hd=`expr $nfhrs - 0`
      infile=$var
      outfile=ge${var}.t${cyc}z.pgrb2a.0p50.${HRINTER}hf$nfhrs
      outfile_gb1=ge${var}.t${cyc}z.pgrba.0p50.${HRINTER}hf$nfhrs
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
           $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PQPF_GB2 $job $COMOUT/${outfile}
        fi
      fi
    done
  done
fi

if [ "$HRINTER" = "12" ]; then
  hourlist="        012 018 024 030 036 042 048 054 060 066 072 078 084 090 096 \
            102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
            204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
            306 312 318 324 330 336 342 348 354 360 366 372 378 384"
  var=pqpf
  for nfhrs in $hourlist; do
    hb=`expr $nfhrs - 12`
    hd=`expr $nfhrs - 0`
    infile=pqpf
    outfile=ge${var}.t${cyc}z.pgrb2a.0p50.${HRINTER}hf$nfhrs
    outfile_gb1=ge${var}.t${cyc}z.pgrba.0p50.${HRINTER}hf$nfhrs
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
         $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PQPF_GB2 $job $COMOUT/${outfile}
      fi
    fi
  done
fi

if [ "$HRINTER" = "24" ]; then
  hourlist="                024 030 036 042 048 054 060 066 072 078 084 090 096 \
            102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
            204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
            306 312 318 324 330 336 342 348 354 360 366 372 378 384"
  var=pqpf
  for nfhrs in $hourlist; do
    hb=`expr $nfhrs - 24`
    hd=`expr $nfhrs - 0`
    infile=pqpf
    outfile=ge${var}.t${cyc}z.pgrb2a.0p50.${HRINTER}hf$nfhrs
    outfile_gb1=ge${var}.t${cyc}z.pgrba.0p50.${HRINTER}hf$nfhrs
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
         $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PQPF_GB2 $job $COMOUT/${outfile}
      fi
    fi
  done
fi

set +x
echo " "
echo "Leaving sub script exnaefs_gefs_pgrb_enspqpf.sh"
echo " "
set -x


