#!/bin/ksh
###################################################################
echo "----------------------------------------------------"
echo "exnawips_gefs_bias.sh.sms - convert NCEP GRIB files into GEMPAK Grids for GEFS Bias"
echo "----------------------------------------------------"
echo "History: Jan 2012 - First implementation of this new script."
#####################################################################

set -xa

export DATA=$1
export fstart=$2
export fend=$3
export COMIN=$4
export COMOUT=$5
export RUN=$6
export model=$7
export DBN_ALERT_TYPE=$8
if [ $# = 9 ]; then
  if [ $model = dvrtma ]; then
    export region=$9
  else
    export member=$9
  fi
fi

if [ ! -d $COMOUT ]; then 
  mkdir -p $COMOUT
fi

cd $DATA
msg="Begin job for $job"
postmsg "$jlogfile" "$msg"

cp $HOMEnaefs/gempak/fix/g2varsncep1.tbl .
cp $HOMEnaefs/gempak/fix/g2vcrdncep1.tbl .
#cp $HOMEnaefs/gempak/fix/g2varswmo2.tbl .
cp $HOMEnaefs/gempak/fix/g2varswmo2_naefs.tbl g2varswmo2.tbl
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
#   fhr=`printf "%03d" $fhr`
    typeset -Z3 fhr
  else
#   fhr=`printf "%02d" $fhr`
    typeset -Z2 fhr
  fi

  fhr3=$fhcnt
# fhr3=`printf "%03d" $fhr`
  typeset -Z3 fhr3
 
  case $RUN in 
    ge*)     if test "$model" = "glbanl"
             then
               GRIBIN=$COMIN/${model}.${cycle}.pgrb2a.0p50_mdf${fhr3}
               GEMGRD=${model}_${PDYm2}${cyc}f${fhr3}
             elif test "$model" = "ndgd"
             then 
               GRIBIN=$COMIN/${RUN}.${cycle}.${model}_conusf${fhr}.grib2
               GEMGRD=${RUN}${model}_${PDY}${cyc}f${fhr3}
             elif test "$model" = "ndgd_alaska"
             then
               GRIBIN=$COMIN/${RUN}.${cycle}.${model}f${fhr}.grib2
               GEMGRD=${RUN}${model}_${PDY}${cyc}f${fhr3}
             elif test "$model" = "avgan"
             then
               GRIBIN=$COMIN/geavg.${cycle}.pgrb2a.0p50_anf${fhr3}
               GEMGRD=${RUN}${model}_${PDY}${cyc}f${fhr3}
             else		# model= bc,an,wt,me anv
               GRIBIN=$COMIN/${RUN}.${cycle}.pgrb2a.0p50_${model}f${fhr3}
               GEMGRD=${RUN}${model}_${PDY}${cyc}f${fhr3}
            fi;;
    naefs)  if test "$model" = "geavganv"
            then
              GRIBIN=$COMIN/${RUN}_geavg.${cycle}.pgrb2a.0p50_anvf${fhr3}
              GEMGRD=${model}_${PDY}${cyc}f${fhr3}
            elif test "$model" = "geavgan"
            then
              GRIBIN=$COMIN/${RUN}_geavg.${cycle}.pgrb2a.0p50_anf${fhr3}
              GEMGRD=${model}_${PDY}${cyc}f${fhr3}
            elif test "$model" = "geefi"
            then
              GRIBIN=$COMIN/${RUN}_geefi.${cycle}.pgrb2a.0p50_bcf${fhr3}
              GEMGRD=${model}_${PDY}${cyc}f${fhr3}
            elif test "$model" = "ndgd"
            then
              GRIBIN=$COMIN/${RUN}.${cycle}.ge${member}.f${fhr3}.conus_ext_2p5.grib2
              GEMGRD=${model}ge${member}_${PDY}${cyc}f${fhr3}
            elif test "$model" = "ndgd_alaska"
            then
              GRIBIN=$COMIN/${RUN}.${cycle}.ge${member}.f${fhr3}.alaska_3p0.grib2
#              GRIBIN=$COMIN/${RUN}_ge${member}.${cycle}.${model}f${fhr}.grib2
              GEMGRD=${model}ge${member}_${PDY}${cyc}f${fhr3}
            elif test "$model" = "dvrtma"
            then
               if test "$region" = "alaska"
               then
                 GRIBIN=$COMIN/${model}.${cycle}.alaska_3p0.grib2
                 GEMGRD=${model}_${region}_${PDY}${cyc}
               else
                 GRIBIN=$COMIN/${model}.${cycle}.conus_ext_2p5.grib2
                 GEMGRD=${model}_${PDY}${cyc}
               fi
            else
              GRIBIN=$COMIN/${RUN}_${model}.${cycle}.pgrb2a.0p50_bcf${fhr3}
              GEMGRD=${model}_${PDY}${cyc}f${fhr3}
            fi;;
          cmc) GRIBIN=$COMIN/${RUN}_${model}.${cycle}.pgrb2a.0p50.f${fhr3}
               GEMGRD=${RUN}_${model}_${PDY}${cyc}f${fhr3}
               ;;
    fnmoc_ge*) if test "$model" = "an" 
              then
                GRIBIN=$COMIN/${RUN}.${cycle}.pgrb2a_${model}f${fhr}
                GEMGRD=${RUN}${model}_${PDY}${cyc}f${fhr3}
              else
                GRIBIN=$COMIN/ENSEMBLE.MET.fcst_${model}0${member}.${fhr3}.${PDY}${cyc}
                if test "model" = "bc"
                then
                  GEMGRD=${RUN}${model}_${PDY}${cyc}f${fhr3}
                else
                  GEMGRD=${RUN}_${PDY}${cyc}f${fhr3}
                fi
              fi ;;
        ecme*) if test "$model" = "bc"
               then
                 GRIBIN=$COMIN/${RUN}.${cycle}.pgrb2a_${model}.1p00.f${fhr3}
                 GEMGRD=${RUN}_${PDY}${cyc}f${fhr3}
               elif test "$model" = "ndgd"
               then
                 GRIBIN=$COMIN/${RUN}.${cycle}.ge${member}.f${fhr3}.conus_ext_2p5.grib2
                 GEMGRD=${model}${member}_${PDY}${cyc}f${fhr3}
               elif test "$model" = "ndgd_alaska"
               then
                 GRIBIN=$COMIN/${RUN}.${cycle}.ge${member}.f${fhr3}.alaska_3p0.grib2
                 GEMGRD=${model}${member}_${PDY}${cyc}f${fhr3}
               fi ;;
  esac
  
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
       # if [ $SENDDBN = "YES" ] ; then
       if [ $SENDDBN = "YES" -a $model != "geavgan" -a $model != "geefi" ] ; then
           $DBNROOT/bin/dbn_alert MODEL ${DBN_ALERT_TYPE} $job \
           $COMOUT/$GEMGRD
       else
         echo "##### DBN_ALERT_TYPE is: ${DBN_ALERT_TYPE} #####"
         echo "Data NOT alert: SENDDBN=$SENDDBN, model=$model"
       fi
    fi

  fi      # skip

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
