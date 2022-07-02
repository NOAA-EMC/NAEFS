#!/bin/ksh
###################################################################
echo "----------------------------------------------------"
echo "exnawips - convert FNMOC GRIB files into GEMPAK Grids"
echo "----------------------------------------------------"
echo "History: Jan 2011 - First implementation of this new script."
#####################################################################


set -xa
msg="Begin job for $job"
postmsg "$jlogfile" "$msg"

#
#export MM=`echo $1 |cut -c2-3`
#export DATA=$2
#export SUBRUN=fnmoc_ge$1
export DATA=$1
export fstart=$2
export fend=$3
export COMIN=$4
export COMOUT=$5
export SUBRUN=$6
export model=$7
export DBN_ALERT_TYPE=$8
if [ $# = 9 ]; then
  export member=$9
fi

cd $DATA

NAGRIB=nagrib_nc
GEMGRDN=outn.gem
GEMGRDS=outs.gem
PDY2=`echo $PDY | cut -c3-`
#

cpyfil=gds
garea=dset
gbtbls=
maxgrd=4999
kxky=
grdarea=
proj=
output=T
pdsext=no
#

maxtries=180
fhcnt=$fstart
while [ $fhcnt -le $fend ] ; do
  if [ $fhcnt -ge 100 ] ; then
    typeset -Z3 fhr
  else
    typeset -Z2 fhr
  fi
  fhr=$fhcnt

  fhr3=$fhcnt
  typeset -Z3 fhr3

#  GRIBIN=$COMIN/${SUBRUN}.${cycle}.pgrbaf${fhr}
  GRIB2IN=$COMIN/ENSEMBLE.MET.fcst_${model}0${member}.${fhr3}.${PDY}${cyc}
  GRIBIN=${SUBRUN}.${cycle}.pgrbaf${fhr}
if [ -s $COMIN/ENSEMBLE.MET.fcst_${model}0${member}.${fhr3}.${PDY}${cyc} ]
then
  $CNVGRIB -g21 $GRIB2IN $GRIBIN

  if [ $model = "bc" ]
  then
    GEMGRD=${SUBRUN}${model}_${PDY}${cyc}f${fhr3}
  else
    GEMGRD=${SUBRUN}_${PDY}${cyc}f${fhr3}
  fi

$GEMEXE/$NAGRIB << EOF
   GBFILE   = $GRIBIN
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

###################################################################
# THERE IS A PROBLEM WITH THE 00-HOUR FORECAST TIME IN THE 
# OUTPUT GRID...THERE IS NO F000 AT THE END OF THE GRID DATE/TIME
# THIS CAUSES PROBLEMS DISPLAYING IN N-AWIPS.
# BELOW WILL ATTEMPT TO FIX THE PROBLEM.
##################################################################
if [ $fhr -eq 00 ]; then
  $GEMEXE/gdinfo << EOF
   GDFILE  = $GEMGRD
   LSTALL  = YES
   OUTPUT  = F/parms.txt
   GLEVEL  = ALL
   GDATTIM = $PDY2/${cyc}00
   GVCORD  = ALL 
   GFUNC   = ALL
   run

   exit
EOF

 if [ -f parms.txt ]; then
   numlines=`wc -l parms.txt | awk '{print $1}'`
   cnt=1

   while [ $cnt -le $numlines ]; do
       txtline=`cat parms.txt | head -n $cnt | tail -1`
       if [ `echo $txtline | grep -c "$PDY2/${cyc}00"` -eq 1 ]; then
         clev=`echo $txtline | awk '{print $3}'`
         cvcord=`echo $txtline | awk '{print $4}'`
         cparm=`echo $txtline | awk '{print $5}'`

         $GEMEXE/gddiag << EOF
          GDFILE  = $GEMGRD
          GDOUTF  = $GEMGRD
          GFUNC   = $cparm
          GDATTIM = $PDY2/${cyc}00
          GLEVEL  = $clev
          GVCORD  = $cvcord
          GRDNAM  = ${cparm}^$PDY2/${cyc}00F000
          GPACK   =
          GRDHDR  =
          PROJ    =
          GRDAREA =
          KXKY    =
          MAXGRD  = 4999
          CPYFIL  = $GEMGRD
          ANLYSS  = 4/2;2;2;2
          run

          exit
EOF
        
         $GEMEXE/gddelt << EOF
          GDFILE  = $GEMGRD
          GDATTIM = $PDY2/${cyc}00
          GLEVEL  = $clev
          GVCORD  = $cvcord
          GFUNC   = $cparm
          run

          exit
EOF

       fi
       let cnt=cnt+1
   done
   rm -f parms.txt
 fi

fi    # if fhr=00

 export err=$?;err_chk

 #####################################################
 # GEMPAK DOES NOT ALWAYS HAVE A NON ZERO RETURN CODE
 # WHEN IT CAN NOT PRODUCE THE DESIRED GRID.  CHECK
 # FOR THIS CASE HERE.
 #####################################################

 ls -l $GEMGRD
 export err=$?;export pgm="GEMPAK CHECK FILE";err_chk

 #####################################################
 # Move the file to /com and issue the DBNet alert
 #####################################################

 if [ $SENDCOM = "YES" ] ; then
   mv $GEMGRD $COMOUT/$GEMGRD
   if [ $SENDDBN = "YES" ] ; then
       $DBNROOT/bin/dbn_alert MODEL ${DBN_ALERT_TYPE} $job \
         $COMOUT/$GEMGRD
   fi
 fi

elif [ ! -s $COMIN/ENSEMBLE.MET.fcst_${model}0${member}.${fhr3}.${PDY}${cyc} ]; then
  echo "WARNING:$COMIN/ENSEMBLE.MET.fcst_${model}0${member}.${fhr3}.${PDY}${cyc} is missing"
fi
 let fhcnt=fhcnt+finc
done

#####################################################################
# GOOD RUN
set +x
echo "**************JOB $SUBRUN NAWIPS COMPLETED NORMALLY ON THE IBM"
echo "**************JOB $SUBRUN NAWIPS COMPLETED NORMALLY ON THE IBM"
echo "**************JOB $SUBRUN NAWIPS COMPLETED NORMALLY ON THE IBM"
set -x
#####################################################################

msg='Job completed normally.'
echo $msg
postmsg "$jlogfile" "$msg"

exit 0
############################### END OF SCRIPT #######################
