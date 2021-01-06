#!/bin/sh
######################### CALLED BY EXENSCQPF ##########################
echo "------------------------------------------------"
echo "Ensemble CQPF -> gefs_enspvrfy.sh               "
echo "------------------------------------------------"
echo "History: Feb 2004 - First implementation of this new script."
echo "AUTHOR: Yuejian Zhu (wx20yz)"
echo "History: Dec 2011 - Upgrade to 1 degree and 6 hourly"
echo "History: Dec 2013 - Change I/O from GRIB1 to GRIB2"
echo "History: Dec 2016 - Upgrade to 0.5 degree and 6 hourly"
echo "AUTHOR: Yan Luo (wx22lu)"

echo "         ######################################### "
echo "         ####  RUN PRECIPTATION VERIFICATION  #### "
echo "         ####  RUN PRECIPTATION VERIFICATION  #### "
echo "         ####  RUN PRECIPTATION VERIFICATION  #### "
echo "         ######################################### "

set -x

export GETGRP=$USHgefs/gefs_ensgetgrp.sh

###
### 6hr-forecast precipitation file name like this
###
### gfs_2010101000_000_006
### ctl_2010101000_000_006
### above two file verified to 2010101000-2010101006
### (/com/gens/prod/gefs.20101010/06/ccpa/ccpa_conus_1.0d_t06z_06h)

 $GETGRP gfs
 $GETGRP ctl

for RUNID in gfs ctl                 
do  
 PRECIP_DATA_FILE=ccpa
 PRECIP_ANALYSIS_FILE=precip.${RUNID}"_"t${cyc}z
 IFDUR=384
  if [ "$RUNID" = "gfs" ]; then
  IFDUR=240
  fi 
 # 1   PATH TO MODEL INFO FILE
 # 2   PATH TO MODEL READIN REGIONAL MASK
 # 3   PATH TO MODEL ON TMP DIRECTORY
 # 4   PATH TO PCP ANALYSIS FILE
 # 5   PATH TO PCP DATA FILE
 # 6   FACTER FOR MRF CTL FORECAST ( Default:1.0 )

cat <<nameEOF >input_runv
model_info_file
$FIXgefs/rfcgrid_0p5.bin                                
$DATA/$cyc                   
$PRECIP_ANALYSIS_FILE
$PRECIP_DATA_FILE
1.0
nameEOF

 # 1   MODEL NAME, SEE GETARCH FOR PROPER SPELLING AND PATH TO ARCHIVE
 # 2   GRID # TO TAKE FROM MODEL GRIB FILE FOR VERIFICATION (-1 MEANS 1ST)
 #     126 for t126 Gaussian Grid. 98 for t62 Gaussian Grid.
 #     144*73 resolution is 2                               
 # 3   NUMBER OF CYCLES AVAILABLE  (ex, 1 for ecmwf, possibly 4 for gfs)
 # 4   CYCLE #1
 # 5   CYCLE #2
 # ...
 # 6   OUTPUT FREQUENCY IN HOURS 
 # 7   FORECAST DURATION IN HOURS 
 # ...REPEAT

cat <<modelEOF >model_info_file
$RUNID
4   
4
0
6
12
18
6
$IFDUR
done
modelEOF

### obs_box.dat contains observation analysis at each grid points
### stat.out contains verification output

# if [ -s obs_box.dat ]; then
#  rm obs_box.dat
# fi

 export pgm=gefs_enspvrfy
 . prep_step

  startmsg

 $EXECgefs/gefs_enspvrfy  <input_runv   >> $pgmout 2>errfile
 export err=$?;err_chk

 cat  stat.out 
 mv stat.out    $DATA/$cyc/rain_$RUNID.$OBSYMD
# mv obs_box.dat $DATA/obs_box_$RUNID.$YMD

done

