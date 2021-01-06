#!/bin/sh
######################### CALLED BY EXENSCQPF ##########################
echo "------------------------------------------------"
echo "Ensemble CQPF -> gefs_enssrbias.sh            "
echo "------------------------------------------------"
echo "History: Feb 2004 - First implementation of this new script."
echo "AUTHOR: Yuejian Zhu (wx20yz)"
echo "History: Dec 2011 - Upgrade to 1 degree and 6 hourly"
echo "History: Dec 2013 - Change I/O from GRIB1 to GRIB2"
echo "History: Dec 2016 - Upgrade to 0.5 degree and 6 hourly"
echo "AUTHOR: Yan Luo (wx22lu)"

echo "         ######################################### "
echo "         ####  RUN NEW STATISTICS BIAS DIST.  #### "
echo "         ####  RUN NEW STATISTICS BIAS DIST.  #### "
echo "         ####  RUN NEW STATISTICS BIAS DIST.  #### "
echo "         ####        RUNNING ID = " $1 "       #### "
echo "         ######################################### "

set -x
RID=$1

 case $RID in 
 gfs) ID_LENGTH=1920;;
 ctl) ID_LENGTH=3072;;
 esac

IYMDP1=`$NDATE +24 $OBSYMD\00 | cut -c1-8`
  length=`cat rain_$RID.$OBSYMD | wc -l`
  mfhr=64
  if [ "$RID" = "gfs" ]; then
  mfhr=40
  fi 

if [ -s STAT_RM_BIAS_$RID.dat ]; then
   cp STAT_RM_BIAS_$RID.dat OLD_STAT.dat
   iold=1  
else
   iold=0
fi

if [ -s rain_$RID.$OBSYMD -a $length -eq $ID_LENGTH ]; then
   cp rain_$RID.$OBSYMD DAY_NEWS.dat
   inew=1  
else
   inew=0
fi

#set +x

if [ $inew -eq 1 ]; then
 echo " &namin " >input_stat
 echo " cfile(1)='$DATA/$cyc/DAY_NEWS.dat',"   >>input_stat
 echo " cfile(2)='$DATA/$cyc/OLD_STAT.dat',"   >>input_stat
 echo " ifile(1)=$inew,"                  >>input_stat
 echo " ifile(2)=$iold,"                  >>input_stat
 echo " ofile(1)='$DATA/$cyc/STAT_RM_BIAS_$RID.txt',"   >>input_stat
 echo " ofile(2)='$DATA/$cyc/NEW_STAT.dat',"   >>input_stat
 echo " iymd=$OBSYMD,"                    >>input_stat
 echo " idday=50,"                        >>input_stat
 echo " mfhr=$mfhr,"                      >>input_stat
 echo " /" >>input_stat
 cat input_stat

 export pgm=gefs_enssrbias
 . prep_step

  startmsg

 $EXECgefs/gefs_enssrbias <input_stat >stat_output.$RID
 export err=$?; err_chk

 cat stat_output.$RID >> $pgmout

 mv NEW_STAT.dat STAT_RM_BIAS_$RID.$IYMDP1
else
 mv OLD_STAT.dat STAT_RM_BIAS_$RID.$IYMDP1
fi

