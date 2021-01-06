#!/bin/sh
######################### CALLED BY EXENSCQPF ##########################
echo "------------------------------------------------"
echo "Ensemble CQPF -> gefs_enswgrp.sh              "
echo "------------------------------------------------"
echo "History: Dec 2011 - First implementation of this new script."
echo "History: Dec 2013 - Change I/O from GRIB1 to GRIB2"
echo "History: Dec 2016 - Upgrade to 0.5 degree and 6 hourly"
echo "AUTHOR: Yan Luo (wx22lu)"

echo "         ######################################### "
echo "         ####  RUN PRECIPTATION VERIFICATION  #### "
echo "         ####  RUN PRECIPTATION VERIFICATION  #### "
echo "         ####  RUN PRECIPTATION VERIFICATION  #### "
echo "         ######################################### "

#set -x

nfhrs=$1

export memberlist="gfs c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"

if [ $cyc -eq 18 ]; then
export YMD=$YMDM1
fi

#####################
## fetch today's forecast   
#####################

 if [ $nfhrs -gt 240 ]; then
    export memberlist="c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"
 fi
  for nens in $memberlist; do
    file=ge${nens}.t${cyc}z.pgrb2a.0p50.f${nfhrs}
    infile=$COMINgefs/gefs.$YMD/${cyc}/pgrb2ap5/$file
    outfile=$DATA/$cyc/geprcp.t${cyc}z.pgrb2a.0p50.f${nfhrs}

    if [ -f $infile ]; then
#    rm $outfile
    >>$outfile
    $WGRIB2 -match ":APCP:" $infile -append -grib $outfile
    else
    echo "echo "no file of" $infile "          
    echo " ***** Missing today's precipitation forecast *****"
    echo " ***** Program must be stoped here !!!!!!!!!! *****"
    export err=8; err_chk
    fi     
  done    # for nens in $memberlist

