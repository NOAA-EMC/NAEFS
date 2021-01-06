#!/bin/ksh
echo "Entering sub script  global_ensstat_cmc.sh"
echo "------------------------------------------------"
echo "Ensemble Statistical Postprocessing (Canadian)"
echo "------------------------------------------------"
echo "History: April 2004 - First implementation of this new script."
echo "based on global_ensstat.sh"
echo "uses same global_ensstat code as global_ensstat.sh"
echo "only produces ensstat files for which enspost exists"
echo "does not produce single-statistic files"
echo "AUTHOR: Richard Wobus (wx20rw)"
echo "modified: Bo Cui      (wx20cb)"

set -x
 
########################################
#  preliminaries
########################################
cd $DATA

export EXECcmce=${EXECcmce:-$HOMEcmce/exec}
export pgm=global_ensstat_cmc
. prep_step

varolist="z500 prcp t2m rh700"
                                                                                                                     
########################################
# high resolution
########################################

for var in $VARLIST
do

  cfipg=enspostc.$cycle.${var}hr

  if [[ -s $cfipg ]]; then

    cfosg=ensstatc.$cycle.${var}hr

    cfomg=ensemblec.emn.$PDY.${cyc}hr

    cfodg=ensemblec.esd.$PDY.${cyc}hr

    echo " &namin"                            >namin
    echo " cfipg"=\"${cfipg}\",              >>namin
    echo " cfosg"=\"${cfosg}\",              >>namin
    echo " cfomg"=\"${cfomg}\",              >>namin
    echo " cfodg"=\"${cfodg}\",              >>namin
    echo " lfm=66000,"                       >>namin
    echo " lf=65160,"                        >>namin

    ((numhour=0))
    for ihour in $HHRLIST
    do
      ((numhour=numhour+1))
      echo " ihour(${numhour})=${ihour},"    >>namin
    done
    echo " numhour=${numhour},"              >>namin
    
    ((nummem=0))
    for mem in $MEMLIST
    do
      mema=`echo $mem|cut -c1,1`
      memb=`echo $mem|cut -c2,`
      if [[ "$mema" = "p" ]]; then
       ((nummem=nummem+1))
      fi
    done
    echo " nummem=${nummem}"                 >>namin
    echo " / "                               >>namin

    cat namin

    startmsg
    $EXECcmce/$pgm <namin>$pgmout 2>errfile
    export err=$?; err_chk
    mv namin namin.$var.lr

    for varo in $varolist
    do
      if [[ $var = $varo ]]; then
        echo "################################### $var high-resolution output begin"
 	cat $pgmout
 	echo "################################### $var high-resolution output end"
 	mv $pgmout $pgmout.$var.hr
      fi
     done

  fi

done

echo "Leaving sub script  global_ensstat_cmc.sh"
