#!/bin/sh
########################### RTMA_BIAS ################################################
echo "------------------------------------------------"
echo "Update Downscaling Vector For Hawaii between RTMA and NCEP operational analysis"
echo "------------------------------------------------"
echo "History: Jan 2016 - First implementation of this new script."
echo "AUTHOR: Bo Cui  (wx20cb)"
######################################################################################

##############################################
# define exec variable, and entry grib utility 
##############################################
set -x
export pgm=dvrtma_bias_alaska          
. prep_step

#########################################
# define rtma grids for different regions             
#########################################

if [ "$regid" = "ak" ]; then
  region=alaska_3p0
  grid='20 6 0 0 0 0 0 0 1649 1105 40530101 181429000 8 60000000 210000000 2976563 2976563 0 64'
elif [ "$regid" = "conus" ]; then
  region=conus_ext_2p5  
  grid="30 6 0 0 0 0 0 0 2145 1597 20191999 238445999 8 25000000 265000000 \
      2539703 2539703 0 64 25000000 25000000 -90000000 0"
elif [ "$regid" = "hi" ]; then
  region=hawaii
  grid='10 1 0 6371200 0 0 0 0 321 225 18072699 198474999 56 20000000 23087799 206130999 64 0 2500000 2500000'
elif [ "$regid" = "gu" ]; then
  region=guam   
  grid='10 1 0 6371200 0 0 0 0 193 193 12349884 143686538 56 20000000 16794399 148280000 64 0 2500000 2500000'
elif [ "$regid" = "pr" ]; then
  region=puri   
  grid='10 1 0 6371200 0 0 0 0 177 129 16828685 291804687 56 20000000 19747399 296027600 64 0 2500000 2500000'
fi

#############################################################
### Step 1: calculate downscaling vector for different cycle                   
#############################################################

###
# set the decaying average weight
###

weight=0.30

###
# rtma analysis files entry
###

if [ "$regid" = "conus" ]; then
  COMINRTMA=${COM_RTMA}/rtma2p5.${PDY}
  afile=rtma2p5.t${cyc}z.2dvaranl_ndfd.grb2_ext
elif [ "$regid" = "ak" ]; then
  COMINRTMA=${COM_RTMA}/${regid}rtma.${PDY}
  afile=akrtma.t${cyc}z.2dvaranl_ndfd_3p0.grb2
else
  COMINRTMA=${COM_RTMA}/${regid}rtma.${PDY}
  afile=${regid}rtma.t${cyc}z.2dvaranl_ndfd.grb2
fi

if [ -s $COMINRTMA/$afile ]; then
  cp $COMINRTMA/$afile .
else
  echo " FATAL ERROR: No RTMA Analysis"
  export err=9; err_chk
# exit
fi

###
# NCEP operational analysis file entry, interpolate it on grids of different regions
###

infile=$COMINgefs/gec00.t${cyc}z.pgrb2a.0p50.f000
outfile=gec00.t${cyc}z.pgrb2a.0p5.f000_temp
cfile=gec00.t${cyc}z.pgrb2a.0p50.f000_${region}

if [[ ! -s $infile ]]
then
   echo "FATAL ERROR: Input GEFS files not available"
   export err=1; err_chk
fi

>$outfile

$WGRIB2 -match ":PRES"                 $infile          -grib  $outfile
$WGRIB2 -match ":TMP:"  -match "2 m "  $infile  -append -grib  $outfile
$WGRIB2 -match ":DPT:"  -match "2 m "  $infile  -append -grib  $outfile
$WGRIB2 -match ":RH:"   -match "2 m "  $infile  -append -grib  $outfile
$WGRIB2 -match ":UGRD:" -match "10 m " $infile  -append -grib  $outfile
$WGRIB2 -match ":VGRD:" -match "10 m " $infile  -append -grib  $outfile
#$WGRIB2 -match ":TCDC:"                $infile  -append -grib  $outfile

$COPYGB2 -g "$grid" -i3 -x $outfile $cfile

###
# get initialized bias for $cyc, cstart: 1= cold start if bias accumulation
###

cstart=0

#if [ "$regid" = "conus" ]; then
#  ifile=dvrtma.t${cyc}z.${region}_ext_2p5.grib2
#elif [ "$regid" = "ak" ]; then
#  ifile=dvrtma.t${cyc}z.alaska_3p0.grib2             
#else
#  ifile=dvrtma.t${cyc}z.${region}.grib2
#fi

ifile=dvrtma.t${cyc}z.${region}.grib2

pgbme=bias_rtma_opranl

if [ -s $COM_DV/naefs.$PDYm1/${cyc}/ndgd_gb2/$ifile ]; then
  cp $COM_DV/naefs.$PDYm1/${cyc}/ndgd_gb2/$ifile $pgbme
elif [ -s $COM_DV/naefs.$PDYm2/${cyc}/ndgd_gb2/$ifile ]; then
  cp $COM_DV/naefs.$PDYm2/${cyc}/ndgd_gb2/$ifile $pgbme
elif [ -s $COM_DV/naefs.$PDYm3/${cyc}/ndgd_gb2/$ifile ]; then
  cp $COM_DV/naefs.$PDYm3/${cyc}/ndgd_gb2/$ifile $pgbme
elif [ -s $COM_DV/naefs.$PDYm4/${cyc}/ndgd_gb2/$ifile ]; then
  cp $COM_DV/naefs.$PDYm4/${cyc}/ndgd_gb2/$ifile $pgbme
elif [ -s $COM_DV/naefs.$PDYm5/${cyc}/ndgd_gb2/$ifile ]; then
  cp $COM_DV/naefs.$PDYm5/${cyc}/ndgd_gb2/$ifile $pgbme
elif [ -s $COM_DV/naefs.$PDYm6/${cyc}/ndgd_gb2/$ifile ]; then
  cp $COM_DV/naefs.$PDYm6/${cyc}/ndgd_gb2/$ifile $pgbme
elif [ -s $COM_DV/naefs.$PDYm7/${cyc}/ndgd_gb2/$ifile ]; then
  cp $COM_DV/naefs.$PDYm7/${cyc}/ndgd_gb2/$ifile $pgbme
else
  echo "Cold Start for Bias Estimation between RTMA and NCEP Operational Analysis"
  cstart=1
fi

###
#  output ensemble forecasting bias estimation
###

ofile=dvrtma.t${cyc}z.${region}.grib2           

###

echo "&message"  >input
echo " icstart=${cstart}," >> input
echo " dec_w=${weight}," >> input
echo "/" >>input

ln -sf $pgbme fort.11
ln -sf $afile fort.12
ln -sf $cfile fort.13
ln -sf $ofile fort.51

startmsg
$EXECrtma/$pgm  <input > $pgmout.$cyc
export err=$?;err_chk

if [ -s  $ofile ]; then
  if [ "$SENDCOM" = "YES" ]; then
    cp $ofile ${COMOUT_GEFS}/
    cp $ofile ${COMOUT}/
    if [ "$SENDDBN" = "YES" ]; then
      $DBNROOT/bin/dbn_alert MODEL NAEFS_RTMANDGD_GB2 $job $COMOUT/${ofile}
    fi
  fi
else
  echo "FATAL ERROR: $ofile is not generated "
  export err=99; err_chk
fi

#################################################
### Step 2: calculate downscalling vector average 
#################################################

export pgm2=gefs_dv_gen

PDYm06=`$NDATE -6 $PDY$cyc | cut -c1-8`
cycm06=`$NDATE -6 $PDY$cyc | cut -c9-10`
PDYm03=`$NDATE -3 $PDY$cyc | cut -c1-8`
cycm03=`$NDATE -3 $PDY$cyc | cut -c9-10`

nfile=0
if [ -s namin_${cycm03}_dvgen ]; then
  rm namin_${cycm03}_dvgen
fi

echo " &namens" >>namin_${cycm03}_dvgen

iskip=1
ifile=dvrtma.t${cycm06}z.${region}.grib2            
file=$COM_DV/naefs.$PDYm06/${cycm06}/ndgd_gb2/$ifile 

if [ -s $file ]; then
  iskip=0
  (( nfile = nfile + 1 ))
fi
echo " cfipg(1)='${file}'," >>namin_${cycm03}_dvgen
echo " iskip(1)=${iskip},"  >>namin_${cycm03}_dvgen

iskip=1
file=dvrtma.t${cyc}z.${region}.grib2             

if [ -s $file ]; then
  iskip=0
  (( nfile = nfile + 1 ))
fi
echo " cfipg(2)='${file}'," >>namin_${cycm03}_dvgen
echo " iskip(2)=${iskip},"  >>namin_${cycm03}_dvgen
echo " nfiles=$nfile,"      >>namin_${cycm03}_dvgen

ofile=dvrtma.t${cycm03}z.${region}.grib2
echo " cfopg1='${ofile}',"   >>namin_${cycm03}_dvgen
echo " /" >>namin_${cycm03}_dvgen

startmsg
$EXECrtma/${pgm2} <namin_${cycm03}_dvgen > $pgmout.${cycm03}
export err=$?; err_chk

if [ "$SENDCOM" = "YES" ]; then
  cp $ofile ${COMOUTm03_GEFS}/
  cp $ofile ${COMOUTm03}/
fi

msg="HAS COMPLETED NORMALLY!"
postmsg "$jlogfile" "$msg"

exit 0
