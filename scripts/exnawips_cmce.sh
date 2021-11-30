#!/bin/ksh
###################################################################
echo "----------------------------------------------------"
echo "exnawips - convert NCEP GRIB files into GEMPAK Grids"
echo "----------------------------------------------------"
echo "History: Mar 2000 - First implementation of this new script."
echo "S Lilly: May 2008 - add logic to make sure that all of the "
echo "                    data produced from the restricted ECMWF"
echo "                    data on the CCS is properly protected."
echo "C. Magee: 10/2013 - swap X and Y for rtgssthr Atl and Pac."
#####################################################################

set -xa

export DATA=$1
export fstart=$2
export fend=$3
export RUN=$4
export member=$5
cd $DATA

msg="Begin job for $job"
postmsg "$jlogfile" "$msg"

cp $HOMEnaefs/gempak/fix/g2varswmo2.tbl g2varswmo4.tbl
cp $HOMEnaefs/gempak/fix/g2vcrdwmo2.tbl g2vcrdwmo4.tbl

cp $HOMEnaefs/gempak/fix/g2varswmo2.tbl g2varscms1.tbl
cp $HOMEnaefs/gempak/fix/g2varswmo2.tbl g2varscms0.tbl

cp $HOMEnaefs/gempak/fix/g2vcrdncep1.tbl g2vcrdcms0.tbl  

#
NAGRIB_TABLE=$HOMEnaefs/gempak/fix/nagrib.tbl
NAGRIB=nagrib2  
#

entry=`grep "^$RUN " $NAGRIB_TABLE | awk 'index($1,"#") != 1 {print $0}'`

if [ "$entry" != "" ] ; then
  cpyfil=`echo $entry  | awk 'BEGIN {FS="|"} {print $2}'`
  garea=`echo $entry   | awk 'BEGIN {FS="|"} {print $3}'`
  gbtbls=`echo $entry  | awk 'BEGIN {FS="|"} {print $4}'`
  maxgrd=`echo $entry  | awk 'BEGIN {FS="|"} {print $5}'`
  kxky=`echo $entry    | awk 'BEGIN {FS="|"} {print $6}'`
  grdarea=`echo $entry | awk 'BEGIN {FS="|"} {print $7}'`
  proj=`echo $entry    | awk 'BEGIN {FS="|"} {print $8}'`
  output=`echo $entry  | awk 'BEGIN {FS="|"} {print $9}'`

  echo $cpyfil $garea $gbtbls $maxgrd $kxky $grdarea $proj $output
else
  cpyfil=gds
  garea=dset
  gbtbls=
  maxgrd=3500
  kxky=
  grdarea=
  proj=
  output=T
fi  
pdsext=no

maxtries=180
fhcnt=$fstart
while [ $fhcnt -le $fend ] ; do
  if [ $fhcnt -ge 100 ] ; then
    typeset -Z3 fhr
  else
    typeset -Z2 fhr
  fi
  fhr=$fhcnt
  fhcnt3=`expr $fhr % 3`

  fhr3=$fhcnt
  typeset -Z3 fhr3

  GRIBIN=$COMIN/cmc_ge${member}.${cycle}.pgrb2a.0p50.f${fhr3}
  if [ -s $GRIBIN ]
  then

  GEMGRD=${RUN}_${PDY}${cyc}f${fhr3}

  GRIBIN_chk=$GRIBIN

  cp $GRIBIN grib$fhr

  export pgm="nagrib2 F$fhr"
  startmsg

  $GEMEXE/$NAGRIB << EOF
   GBFILE   = grib$fhr
   INDXFL   = 
   GDOUTF   = $GEMGRD
   PROJ     = $proj
   GRDAREA  = $grdarea
   KXKY     = $kxky
   MAXGRD   = $maxgrd
   CPYFIL   = $cpyfil
   GAREA    = $garea
   OUTPUT   = $output
   GBTBLS   = $gbtbls
   GBDIAG   = 
   PDSEXT   = $pdsext
  l
  r
EOF
  export err=$?;err_chk

  if [ "$NAGRIB" = "nagrib2" ] ; then
    gpend
  fi

  if [ $SENDCOM = "YES" ] ; then
     cp $GEMGRD $COMOUT/.$GEMGRD
     mv $COMOUT/.$GEMGRD $COMOUT/$GEMGRD
     if [ $SENDDBN = "YES" ] ; then
         $DBNROOT/bin/dbn_alert MODEL ${DBN_ALERT_TYPE} $job \
           $COMOUT/$GEMGRD
     else
       echo "##### DBN_ALERT_TYPE is: ${DBN_ALERT_TYPE} #####"
     fi
  fi

else 
  echo "WARNING:$GRIB2IN is missing!!!"
fi

  if [ $fhcnt -lt 192 ] ; then
    finc=03
  else
    finc=06
  fi
  let fhcnt=fhcnt+finc
done

#####################################################################
# GOOD RUN
set +x
echo "**************JOB $RUN NAWIPS COMPLETED NORMALLY ON THE IBM"
echo "**************JOB $RUN NAWIPS COMPLETED NORMALLY ON THE IBM"
echo "**************JOB $RUN NAWIPS COMPLETED NORMALLY ON THE IBM"
set -x
#####################################################################

msg='Job completed normally.'
echo $msg
postmsg "$jlogfile" "$msg"

exit 0
############################### END OF SCRIPT #######################

