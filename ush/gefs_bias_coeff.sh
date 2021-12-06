#!/bin/sh
########################### BIASUPDATE #############################
echo "--------------------------------------------------"
echo "Update Avergaed Parameters and Coefficient r Daily  "
echo "--------------------------------------------------"
echo "History: Aug. 2016 - First implementation of this new script."
echo "AUTHOR: Hong Guan "
#####################################################################

mkdir -p $DATA/dir_coeff
cd $DATA/dir_coeff

##############################################
# define exec variable, and entry grib utility 
##############################################
set -x

export pgm=gefs_coeff_r 
. prep_step

##############################################
# define if use the bar files in fix directory 
##############################################
IFFIXBARS=NO 

############################################
### input the variable list for R estimation
############################################

export dec_w=0.2

fieldlist=" 1000HGT  925HGT  850HGT  700HGT  500HGT  250HGT  200HGT  100HGT  50HGT  10HGT \
            1000TMP  925TMP  850TMP  700TMP  500TMP  250TMP  200TMP  100TMP  50TMP  10TMP \
            1000UGRD 925UGRD 850UGRD 700UGRD 500UGRD 250UGRD 200UGRD 100UGRD 50UGRD 10UGRD \
            1000VGRD 925VGRD 850VGRD 700VGRD 500VGRD 250VGRD 200VGRD 100VGRD 50VGRD 10VGRD \
            2MTMP 10MUGRD 10MVGRD "

nvar=0

if [ -s namin.varlist ]; then
  rm namin.varlist
fi

echo " &varlist" >>namin.varlist

for cfield in $fieldlist; do

  ffd=dummy

  case $cfield in

  1000HGT) ffd=z1000;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=100000;bar=90.26;;
   925HGT) ffd=z925;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=92500;bar=732.97;;
   850HGT) ffd=z850;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=85000;bar=1422.14;;
   700HGT) ffd=z700;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=70000;bar=2974.66;;
   500HGT) ffd=z500;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=50000;bar=5554.05;;
   250HGT) ffd=z250;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=25000;bar=10364.6;;
   200HGT) ffd=z200;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=20000;bar=11794.6;;
   100HGT) ffd=z100;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=10000;bar=16068.1;;
    50HGT) ffd=z50; ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=5000;bar=20296.3;;
    10HGT) ffd=z10; ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=1000;bar=30509.1;;

  1000TMP) ffd=t1000;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=100000;bar=283.097;;
   925TMP) ffd=t925;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=92500;bar=279.145;;
   850TMP) ffd=t850;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=85000;bar=276.196;;
   700TMP) ffd=t700;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=70000;bar=268.69;;
   500TMP) ffd=t500;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=50000;bar=253.944;;
   250TMP) ffd=t250;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=25000;bar=221.656;;
   200TMP) ffd=t200;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=20000;bar=216.671;;
   100TMP) ffd=t100;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=10000;bar=206.673;;
    50TMP) ffd=t50; ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=5000;bar=210.757;;
    10TMP) ffd=t10; ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=1000;bar=225.165;;

  1000UGRD) ffd=u1000;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=100000;bar=-0.266545;;
   925UGRD) ffd=u925;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=92500;bar=0.294652;;
   850UGRD) ffd=u850;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=85000;bar=1.15591;;
   700UGRD) ffd=u700;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=70000;bar=2.86733;;
   500UGRD) ffd=u500;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=50000;bar=5.63068;;
   250UGRD) ffd=u250;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=25000;bar=11.7817;;
   200UGRD) ffd=u200;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=20000;bar=12.3226;;
   100UGRD) ffd=u100;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=10000;bar=10.0751;;
    50UGRD) ffd=u50; ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=5000;bar=7.8926;;
    10UGRD) ffd=u10; ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=1000;bar=5.56478;;

  1000VGRD) ffd=v1000;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=100000;bar=0.432419;;
   925VGRD) ffd=v925;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=92500;bar=0.53394;;
   850VGRD) ffd=v850;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=85000;bar=0.292321;;
   700VGRD) ffd=v700;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=70000;bar=3.68348e-06;;
   500VGRD) ffd=v500;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=50000;bar=-0.0628255;;
   250VGRD) ffd=v250;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=25000;bar=-0.240181;;
   200VGRD) ffd=v200;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=20000;bar=-0.569882;;
   100VGRD) ffd=v100;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=10000;bar=-0.0151515;;
    50VGRD) ffd=v50; ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=5000;bar=0.00277778;;
    10VGRD) ffd=v10; ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=1000;bar=-0.008562;;

      TMAX) ffd=t2max;ipdn=11;ipd1=0;ipd2=4;ipd10=103;ipd11=0;ipd12=2;bar=-9999.99;;
      TMIN) ffd=t2min;ipdn=11;ipd1=0;ipd2=5;ipd10=103;ipd11=0;ipd12=2;bar=-9999.99;;
     PRMSL) ffd=prmsl;ipd1=3;ipd2=1;ipd10=101;ipd11=0;ipd12=0;bar=-9999.99;;
      PRES) ffd=pres; ipd1=3;ipd2=0;ipd10=1;  ipd11=0;ipd12=0;bar=-9999.99;;
   10MUGRD) ffd=u10m; ipd1=2;ipd2=2;ipd10=103;ipd11=0;ipd12=10;bar=-0.223379;;
   10MVGRD) ffd=v10m; ipd1=2;ipd2=3;ipd10=103;ipd11=0;ipd12=10;bar=0.406965;;
     2MTMP) ffd=t2m;  ipd1=0;ipd2=0;ipd10=103;ipd11=0;ipd12=2;bar=280.895;;
  ULWRFsfc) ffd=ulwrfsfc;ipdn=11;ipd1=5;ipd2=193;ipd10=1;ipd11=0;ipd12=0;bar=-9999.99;;
  ULWRFtop) ffd=ulwrftop;ipdn=11;ipd1=5;ipd2=193;ipd10=8;ipd11=0;ipd12=0;bar=-9999.99;;
   850VVEL) ffd=vvel; ipd1=2;ipd2=8;ipd10=100;ipd11=0;ipd12=85000;bar=-9999.99;;
      2MRH) ffd=rh2m; ipd1=1;ipd2=1;ipd10=103;ipd11=0;ipd12=2;bar=-9999.99;;
     2MDPT) ffd=dpt2m;ipd1=0;ipd2=6;ipd10=103;ipd11=0;ipd12=2;bar=-9999.99;;

  esac

  if [ "$ffd" == "dummy" ]; then
    echo " #### attention: variable $cfield is not in the list"
  else
    (( nvar = nvar + 1 ))
    echo "ffd($nvar)='$ffd',bar($nvar)=$bar,"   >>namin.varlist
    echo "jpd1($nvar)=$ipd1,jpd2($nvar)=$ipd2,jpd10($nvar)=$ipd10,jpd11($nvar)=$ipd11,jpd12($nvar)=$ipd12," >>namin.varlist
  fi

done

echo "jnvar=$nvar," >>namin.varlist
echo " /"           >>namin.varlist

############################################################
# input basic information, member and forecast lead time
############################################################

coefflist="abar fbar saabar sffbar sfabar"

memlist="avg"

###########################################################
### calculate R estimation for different forecast lead time
###########################################################

for nens in $memlist; do

 for nfhrs in $hrlist_6hr; do

###
# analysis files entry
###

  fymdh=${PDYm1}18
  fymdh=`$NDATE -$nfhrs $fymdh `
  fymd=`echo $fymdh | cut -c1-8`

  aymdh=`$NDATE +$nfhrs $fymd$cyc `
  aymd=`echo $aymdh | cut -c1-8`
  acyc=`echo $aymdh | cut -c9-10`

  aymdh_m06=`$NDATE -6 $aymdh `
  aymd_m06=`echo $aymdh_m06 | cut -c1-8`
  acyc_m06=`echo $aymdh_m06 | cut -c9-10`

  afile=$COMINgefs/gefs.${aymd}/${acyc}/atmos/pgrb2ap5/gec00.t${acyc}z.pgrb2a.0p50.f000

  if [ -s $afile ]; then
    echo " "
  else
    echo " There is no Analysis data, Stop! for " $acyc 
  fi

###
# forecast files entry
###

  cfile=$COMINgefs/gefs.${fymd}/${cyc}/atmos/pgrb2ap5/ge${nens}.t${cyc}z.pgrb2a.0p50.f$nfhrs

  if [ -s $cfile ]; then
   echo " "
  else
    echo " There is no Forecast data for " $acyc 
  fi

###
# get initialized bar files for $nens at $nfhrs
# set the no cold start index as default, 0
###

  cstart=0

  CDATE=$PDY$cyc
  icnt=0
  while [ $icnt -le 16 ]; do

    CDATE=`$NDATE -24 $CDATE`
    PDYm=`echo $CDATE | cut -c1-8`

    ncoeff=0
    for coeff in $coefflist; do
      infilebar=ge${nens}.t${cyc}z.pgrb2a.0p50_${coeff}f$nfhrs
      outfilebar=ge${nens}.t${cyc}z.i${coeff}f$nfhrs
      if [ -s $COMINbias/gefs.$PDYm/${cyc}/pgrb2ap5/$infilebar ]; then
        cp $COMINbias/gefs.$PDYm/${cyc}/pgrb2ap5/$infilebar $outfilebar
        (( ncoeff = ncoeff + 1 ))
      fi
    done

    if [ $ncoeff -eq 5 ]; then
      icnt=17
    else
      icnt=`expr $icnt + 1`
    fi

  done

  if [ $ncoeff -eq 0 ]; then
    if [ "$IFFIXBARS" = "YES" ]; then                     
      echo "No Enough Coefficient Files, Copy Files from Fix Directory" 
      for coeff in $coefflist; do
        file=${coeff}.0p50_00                          
        if [ ! -s $file ]; then
          cp $FIXgefs/$file .                   
        fi
      done
    else
      echo "Cold Start for r Estimation At " $nfhrs " For " $nens
      cstart=1
    fi
  fi

  if [ "$IFFIXBARS" = "YES" ]; then                     
    if [ $nfhrs -le 99 ]; then
      fhr=`expr $nfhrs - 0 `
    else
      fhr=$nfhrs
    fi
    for coeff in $coefflist; do
      infile=${coeff}.0p50_00                          
      outfile=ge${nens}.t${cyc}z.i${coeff}f$nfhrs
      if [ -s $file ]; then
        >$outfile
        $WGRIB2 -match ":${fhr} hour" $infile -grib $outfile
      fi
    done
  fi

###
# set input file names
###
 
  pgbabar=ge${nens}.t${cyc}z.iabarf$nfhrs
  pgbfbar=ge${nens}.t${cyc}z.ifbarf$nfhrs
  pgbsaabar=ge${nens}.t${cyc}z.isaabarf$nfhrs
  pgbsffbar=ge${nens}.t${cyc}z.isffbarf$nfhrs
  pgbsfabar=ge${nens}.t${cyc}z.isfabarf$nfhrs

###
#  output averaged parameters and squared correlation roefficent estimation
###

  oabar=ge${nens}.t${cyc}z.pgrb2a.0p50_abarf${nfhrs}
  ofbar=ge${nens}.t${cyc}z.pgrb2a.0p50_fbarf${nfhrs}
  osaabar=ge${nens}.t${cyc}z.pgrb2a.0p50_saabarf${nfhrs}
  osffbar=ge${nens}.t${cyc}z.pgrb2a.0p50_sffbarf${nfhrs}
  osfabar=ge${nens}.t${cyc}z.pgrb2a.0p50_sfabarf${nfhrs}
  or2=ge${nens}.t${cyc}z.pgrb2a.0p50_coefff${nfhrs}

  odate=`$NDATE -24 $PDY$cyc `

  echo "&message"  >input.r2.$nfhrs.$nens
  echo " icstart=${cstart}," >> input.r2.$nfhrs.$nens
  echo " nens='$nens'," >>input.r2.$nfhrs.$nens
  echo " dec_w=${dec_w}," >> input.r2.$nfhrs.$nens
  echo " odate=$odate," >>input.r2.$nfhrs.$nens
  echo " FHR=$nfhrs," >>input.r2.$nfhrs.$nens
  echo "/" >>input.r2.$nfhrs.$nens

  cat namin.varlist >>input.r2.$nfhrs.$nens
  
  ln -sf $afile       fort.12
  ln -sf $cfile       fort.14

  ln -sf $pgbabar     fort.20
  ln -sf $pgbfbar     fort.21
  ln -sf $pgbsaabar   fort.22
  ln -sf $pgbsffbar   fort.23
  ln -sf $pgbsfabar   fort.24

  ln -sf $oabar       fort.40
  ln -sf $ofbar       fort.41
  ln -sf $osaabar     fort.42
  ln -sf $osffbar     fort.43
  ln -sf $osfabar     fort.44
  ln -sf $or2         fort.45

  startmsg
  $EXECgefs/$pgm  <input.r2.$nfhrs.$nens > $pgmout.coeff.$nfhrs.${nens} 2> errfile
  export err=$?;err_chk

  rm fort.*

 done
done


set +x
echo " "
echo "Leaving sub script gefs_bias_coeff.sh"
echo " "
set -x

