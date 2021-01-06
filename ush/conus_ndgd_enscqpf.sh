#!/bin/sh
######################### CALLED BY EXENSDSCQPF ##########################
echo "------------------------------------------------"
echo "Ensemble ndgd CQPF -> conus_ndgd_enscqpf.sh     "
echo "------------------------------------------------"
echo "History: Feb 2017 - First implementation of this new script."
echo "AUTHOR: Yan Luo (wx22lu)"

set -x

iacc=$1

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

if [ $cyc -eq 18 ]; then
export YMDH=${YMDM1}\18
fi

cd $DATA/$cyc/${iacc}hr

 ls geprcp.t${cyc}z.ndgd2p5_conus.${iacc}hf*.gb2 gepqpf.t${cyc}z.ndgd2p5_conus.${iacc}hf*.gb2 > ndgd.list
 cat ndgd.list
 sizelist=`ls -l ndgd.list | awk {'print $5'} `
 echo "sizelist == $sizelist"
 if [ $sizelist -ne 0 ]; then
 rm geprcp.t${cyc}z.ndgd2p5_conus.${iacc}hf*.gb2 gepqpf.t${cyc}z.ndgd2p5_conus.${iacc}hf*.gb2
 fi

for fhrs in $hourlist; do

VMM=`$NDATE +${fhrs} $YMDH | cut -c5-6`
VMMDD=`$NDATE +${fhrs} $YMDH | cut -c5-8`

cat <<namEOF >input_ndgd_$fhrs
$DATA/$cyc/${iacc}hr
$FIXndgd/gridndgd2p5rfcs.grb2
$FIXndgd/downscaling_ratio_2002$VMMDD
$cyc
$VMM
$fhrs
$iacc
namEOF

###
###  Downscale current day's (CDATE) forecast
###
cat input_ndgd_$fhrs

 export pgm=conus_ndgd_enscqpf 

 . prep_step

  startmsg

 $EXECndgd/conus_ndgd_enscqpf <input_ndgd_$fhrs   >> $pgmout 2>errfile
 export err=$?;err_chk

done
