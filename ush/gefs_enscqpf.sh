#!/bin/sh
######################### CALLED BY EXENSCQPF ##########################
echo "------------------------------------------------"
echo "Ensemble CQPF -> gefs_enscqpf.sh                "
echo "------------------------------------------------"
echo "History: Dec 2010 - First Development of this new script."
echo "History: Dec 2013 - Change I/O from GRIB1 to GRIB2"
echo "History: Dec 2016 - Upgrade to 0.5 degree and 6 hourly"
echo "AUTHOR: Yan Luo (wx22lu)"

set -x 

 ls geprcp."t"$cyc"z"pgrb2_bc_06hf*  gepqpf."t"$cyc"z".pgrb2_bc_06hf* > cqpf.list
 cat cqpf.list
 sizelist=`ls -l cqpf.list | awk {'print $5'} `
 echo "sizelist == $sizelist"
 if [ $sizelist -ne 0 ]; then
 rm geprcp."t"$cyc"z".pgrb2a.0p50.bc_f*  gepqpf."t"$cyc"z".pgrb2a.0p50.bc_f*
 rm gepqpf."t"$cyc"z".pgrb2a.0p50.f*
 fi 

  hourlist="    006 012 018 024 030 036 042 048 054 060 066 072 078 084 090 096 \
            102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
            204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
            306 312 318 324 330 336 342 348 354 360 366 372 378 384"

for fhrs in $hourlist; do  

infile=$DATA/$cyc/geprcp.t${cyc}z.pgrb2a.0p50.f${fhrs}

if [ -f $infile ]; then
 echo " $infile is available "

cat <<namEOF >input_cqpf_$fhrs
$DATA/$cyc
STAT_RM_BIAS_gfs.$YMD
STAT_RM_BIAS_ctl.$YMD
$FIXgefs/rfcgrid_0p5.bin
$cyc
$fhrs
namEOF

###
###  Calibrate current day's (CDATE) forecast
###
cat input_cqpf_$fhrs

 export pgm=gefs_enscqpf_6hr

 . prep_step

  startmsg

 $EXECgefs/gefs_enscqpf_6hr <input_cqpf_$fhrs   >> $pgmout 2>errfile
 export err=$?;err_chk

else
 echo " ***** Missing today's precipitation forecast *****"
 echo " ***** Program must be stoped here !!!!!!!!!! *****"
 export err=8;err_chk
fi

done
