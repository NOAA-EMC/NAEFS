#!/bin/sh
######################### CALLED BY EXENSDSCQPF ##########################
echo "------------------------------------------------"
echo "Ensemble ndgd CQPF -> conus_ndgd_enswgrp.sh     "
echo "------------------------------------------------"
echo "History: Feb 2017 - First implementation of this new script."
echo "AUTHOR: Yan Luo (wx22lu)"

set -x

nfhrs=$1
iacc=$2

grid="30 6 0 0 0 0 0 0 2145 1377 20192000 238446000 8 25000000 265000000 2539000 2539000 0 64 25000000 25000000 -90000000 0"

if [ $cyc -eq 18 ]; then
export YMD=$YMDM1
fi

cd $DATA/$cyc/${iacc}hr

file=geprcp.t${cyc}z.pgrb2a.0p50.bc_${iacc}hf${nfhrs}
infile=$COMIN/gefs.$YMD/${cyc}/prcp_bc_gb2/$file
outfile=$DATA/$cyc/${iacc}hr/geprcp.t${cyc}z.ndgd2p5.bc_${iacc}hf${nfhrs}.gb2

  if [ -f $infile ]; then
     $COPYGB2 -g "${grid}" -i3 -x $infile $outfile
  else
    echo "echo "no file of" $infile "          
    echo " ***** Missing today's precipitation forecast *****"
    echo " ***** Program must be stoped here !!!!!!!!!! *****"
    export err=8; err_chk
  fi
