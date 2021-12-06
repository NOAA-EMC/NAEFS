#!/bin/sh
###################################################################
echo "----------------------------------------------------"
echo "exnawips_conus_ndgd_enscqpf.sh.ecf - convert NCEP GRIB files into GEMPAK Grids for NAEFS precipitaion related product"
echo "----------------------------------------------------"
echo "History: "
echo "Wen Meng Sep 2017 - First development of this new script."
echo "Yan Luo  Sep 2017 - First implementation of this new script."
echo "                    Modified for applying to precipitation product."
#####################################################################

set -xa

export DATA=$1
export fstart=$2
export fend=$3
export COMIN=$4
export COMOUT=$5
export RUN=$6
export hrinter=$7
export DBN_ALERT_TYPE=$8

if [ ! -d $COMOUT ]; then 
  mkdir -p $COMOUT
fi

cd $DATA
msg="Begin job for $job"
postmsg "$jlogfile" "$msg"

cp $HOMEnaefs/gempak/fix/g2varsncep1.tbl .
cp $HOMEnaefs/gempak/fix/g2vcrdncep1.tbl .
cp $HOMEnaefs/gempak/fix/g2varswmo2.tbl .
cp $HOMEnaefs/gempak/fix/g2varswmo2.tbl g2varswmo5.tbl
cp $HOMEnaefs/gempak/fix/g2vcrdwmo2.tbl .
cp $HOMEnaefs/gempak/fix/g2vcrdwmo2.tbl g2vcrdwmo5.tbl

#
#
#NAGRIB_TABLE=/gpfs/hps/nco/ops/nwprod/gempak.v6.32.0/fix/nagrib.tbl
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
else
  cpyfil=gds
  garea=dset
  gbtbls=
  maxgrd=4999
  kxky=
  grdarea=
  proj=
  output=T
fi  
pdsext=no

maxtries=3
fhcnt=$fstart
while [ $fhcnt -le $fend ] ; do
  fhr=$fhcnt

  if [ $fhcnt -ge 100 ] ; then
    fhr=`printf "%03d" $fhr`
  else
    fhr=`printf "%02d" $fhr`
  fi

  fhr3=$fhcnt
  fhr3=`printf "%03d" $fhr`

  GRIBIN=$COMIN/${RUN}.${cycle}.ndgd2p5_conus.${hrinter}f${fhr3}.gb2
  GEMGRD=${RUN}_ndgd2p5_conus_${hrinter}_${PDY}${cyc}f${fhr3}
 
  icnt=1
  skip=0
  while [ $icnt -lt 1000 ]
  do
    if [[ -r $GRIBIN ]] ; then
      break
    else
      let "icnt=icnt+1"
      sleep 20
    fi
    if [ $icnt -ge $maxtries ]
    then
      msg="Skipping F$fhr after 1 minutes of waiting."
      echo $msg
      skip=1
      break
    fi
  done

  if [ $skip = 0 ]; then
    cp $GRIBIN grib$fhr

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

    #####################################################
    # GEMPAK DOES NOT ALWAYS HAVE A NON ZERO RETURN CODE
    # WHEN IT CAN NOT PRODUCE THE DESIRED GRID.  CHECK
    # FOR THIS CASE HERE.
    #####################################################

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

  fi      # skip
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
