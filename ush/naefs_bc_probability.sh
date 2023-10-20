#!/bin/sh
###########################################################################################
# Script: naefs_bc_probability.sh
# Abstract: produces ensemble 10%, 50% and 90% probability forecast
# Author: Bo CUI ---- July 2007
#                     Jan. 2008  use accumulated analysis difference to adjust CMC ensemble 
#                     Apr. 2009 add the option to set NAEFS product ID as 114
#                     July.2010 add FNMOC ensemble 20 members
###########################################################################################

set -x
########################################
#  define ensemble members and lead time
########################################

#hourlist=" 00  06  12  18  24  30  36  42  48  54  60  66  72  78  84  90  96 \
#          102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
#          204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
#          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

#memberlist_ncep="c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"
#memberlist_cmc="c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"
#memberlist_fnmoc="p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"

##################################################
# start probability calculation for each lead time
##################################################

hourlist=$FHRLIST

####################################################################
# define if removing initial analyis difference between CMC and NCEP
# 0 = don't remove difference from CMC/FNMOC ensemble forecast
# 1 = remove difference from CMC ensemble forecast
####################################################################

ifdebias=0

####################################
# judeg if generating NAEFS products
# 0 = use the original product ID
# 1 = set NAEFS product ID as 114
####################################

pidswitch=0

#########################################################
# judeg if use CMC raw relative humility 
# YES = use CMC raws ensemble 2m RH
# NO  = once CMC bias corrected 2m RH, choose this option
#########################################################

IFCMCRAWRH=YES

###############################################
# create variable list for ensmeble conbination
###############################################

fieldlist=" 1000HGT 925HGT 850HGT 700HGT 500HGT 250HGT 200HGT 100HGT 50HGT 10HGT \
            1000TMP 925TMP 850TMP 700TMP 500TMP 250TMP 200TMP 100TMP 50TMP 10TMP \
            1000UGRD 925UGRD 850UGRD 700UGRD 500UGRD 250UGRD 200UGRD 100UGRD 50UGRD 10UGRD \
            1000VGRD 925VGRD 850VGRD 700VGRD 500VGRD 250VGRD 200VGRD 100VGRD 50VGRD 10VGRD \
            PRES PRMSL 2MTMP 10MUGRD 10MVGRD TMAX TMIN 850VVEL 2MDPT 2MRH 10MWSPD "

nvar=0

if [ -s namin.varlist ]; then
  rm namin.varlist
fi

if [ "$IFNAEFS" = "YES" -o  "$IFCMCE" = "YES" ]; then

  echo " &varlist" >>namin.varlist

  for cfield in $fieldlist; do
   
    ffd=dummy

    case $cfield in

    1000HGT) ffd=z1000;ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=100000;icnt=2;;
     925HGT) ffd=z925;ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=92500;icnt=2;;
     850HGT) ffd=z850;ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=85000;icnt=2;;
     700HGT) ffd=z700;ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=70000;icnt=2;;
     500HGT) ffd=z500;ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=50000;icnt=2;;
     250HGT) ffd=z250;ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=25000;icnt=2;;
     200HGT) ffd=z200;ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=20000;icnt=2;;
     100HGT) ffd=z100;ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=10000;icnt=2;;
      50HGT) ffd=z50; ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=5000; icnt=2;;
      10HGT) ffd=z10; ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=1000; icnt=2;;

    1000TMP) ffd=t1000;ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=100000;icnt=2;;
     925TMP) ffd=t925;ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=92500;icnt=2;;
     850TMP) ffd=t850;ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=85000;icnt=2;;
     700TMP) ffd=t700;ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=70000;icnt=2;;
     500TMP) ffd=t500;ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=50000;icnt=2;;
     250TMP) ffd=t250;ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=25000;icnt=2;;
     200TMP) ffd=t200;ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=20000;icnt=2;;
     100TMP) ffd=t100;ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=10000;icnt=2;;
      50TMP) ffd=t50; ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=5000; icnt=2;;
      10TMP) ffd=t10; ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=1000; icnt=2;;

    1000UGRD) ffd=u1000;ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=100000;icnt=2;;
     925UGRD) ffd=u925;ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=92500;icnt=2;;
     850UGRD) ffd=u850;ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=85000;icnt=2;;
     700UGRD) ffd=u700;ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=70000;icnt=2;;
     500UGRD) ffd=u500;ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=50000;icnt=2;;
     250UGRD) ffd=u250;ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=25000;icnt=2;;
     200UGRD) ffd=u200;ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=20000;icnt=2;;
     100UGRD) ffd=u100;ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=10000;icnt=2;;
      50UGRD) ffd=u50; ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=5000; icnt=2;;
      10UGRD) ffd=u10; ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=1000; icnt=2;;

    1000VGRD) ffd=v1000;ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=100000;icnt=2;;
     925VGRD) ffd=v925;ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=92500;icnt=2;;
     850VGRD) ffd=v850;ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=85000;icnt=2;;
     700VGRD) ffd=v700;ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=70000;icnt=2;;
     500VGRD) ffd=v500;ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=50000;icnt=2;;
     250VGRD) ffd=v250;ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=25000;icnt=2;;
     200VGRD) ffd=v200;ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=20000;icnt=2;;
     100VGRD) ffd=v100;ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=10000;icnt=2;;
      50VGRD) ffd=v50; ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=5000; icnt=2;;
      10VGRD) ffd=v10; ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=1000; icnt=2;;

        TMAX) ffd=t2max;ipdn=11;ipd1=0;ipd2=4;ipd10=103;ipd11=0;ipd12=2;icnt=2;;
        TMIN) ffd=t2min;ipdn=11;ipd1=0;ipd2=5;ipd10=103;ipd11=0;ipd12=2;icnt=2;;
       PRMSL) ffd=prmsl;ipdn=1;ipd1=3;ipd2=1;ipd10=101;ipd11=0;ipd12=0;icnt=2;;
        PRES) ffd=pres; ipdn=1;ipd1=3;ipd2=0;ipd10=1;  ipd11=0;ipd12=0;icnt=2;;
     10MUGRD) ffd=u10m; ipdn=1;ipd1=2;ipd2=2;ipd10=103;ipd11=0;ipd12=10;icnt=2;;
     10MVGRD) ffd=v10m; ipdn=1;ipd1=2;ipd2=3;ipd10=103;ipd11=0;ipd12=10;icnt=2;;
       2MTMP) ffd=t2m;  ipdn=1;ipd1=0;ipd2=0;ipd10=103;ipd11=0;ipd12=2;icnt=2;;
    ULWRFsfc) ffd=ulwrfsfc;ipdn=11;ipd1=5;ipd2=193;ipd10=1;ipd11=0;ipd12=0;icnt=2;;
    ULWRFtop) ffd=ulwrftop;ipdn=11;ipd1=5;ipd2=193;ipd10=8;ipd11=0;ipd12=0;icnt=2;;
     850VVEL) ffd=vvel; ipdn=1;ipd1=2;ipd2=8;ipd10=100;ipd11=0;ipd12=85000;icnt=2;;
        2MRH) ffd=rh2m; ipdn=1;ipd1=1;ipd2=1;ipd10=103;ipd11=0;ipd12=2;icnt=2;;
       2MDPT) ffd=dpt2m;ipdn=1;ipd1=0;ipd2=6;ipd10=103;ipd11=0;ipd12=2;icnt=2;;
     10MWSPD) ffd=wspd10m; ipdn=1;ipd1=2;ipd2=1;ipd10=103;ipd11=0;ipd12=10;icnt=2;;

    esac

    if [ "$ffd" == "dummy" ]; then
      echo " #### attention: variable $cfield is not in the list"
    else
      (( nvar = nvar + 1 ))
      echo "ffd($nvar)='$ffd',ipdn($nvar)=$ipdn,mmod($nvar)=$icnt," >>namin.varlist
      echo "ipd1($nvar)=$ipd1,ipd2($nvar)=$ipd2,ipd10($nvar)=$ipd10,ipd11($nvar)=$ipd11,ipd12($nvar)=$ipd12," >>namin.varlist
    fi

  done

  echo "nvar=$nvar," >>namin.varlist
  echo " /" >>namin.varlist

fi

if [ "$IFGEFS" = "YES" ]; then

  echo " &varlist" >>namin.varlist

  for cfield in $fieldlist; do

    ffd=dummy

    case $cfield in

    1000HGT) ffd=z1000;ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=100000;icnt=1;;
     925HGT) ffd=z925;ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=92500;icnt=1;;
     850HGT) ffd=z850;ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=85000;icnt=1;;
     700HGT) ffd=z700;ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=70000;icnt=1;;
     500HGT) ffd=z500;ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=50000;icnt=1;;
     250HGT) ffd=z250;ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=25000;icnt=1;;
     200HGT) ffd=z200;ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=20000;icnt=1;;
     100HGT) ffd=z100;ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=10000;icnt=1;;
      50HGT) ffd=z50; ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=5000; icnt=1;;
      10HGT) ffd=z10; ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=1000; icnt=1;;

    1000TMP) ffd=t1000;ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=100000;icnt=1;;
     925TMP) ffd=t925;ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=92500;icnt=1;;
     850TMP) ffd=t850;ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=85000;icnt=1;;
     700TMP) ffd=t700;ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=70000;icnt=1;;
     500TMP) ffd=t500;ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=50000;icnt=1;;
     250TMP) ffd=t250;ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=25000;icnt=1;;
     200TMP) ffd=t200;ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=20000;icnt=1;;
     100TMP) ffd=t100;ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=10000;icnt=1;;
      50TMP) ffd=t50; ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=5000; icnt=1;;
      10TMP) ffd=t10; ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=1000; icnt=1;;

    1000UGRD) ffd=u1000;ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=100000;icnt=1;;
     925UGRD) ffd=u925;ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=92500;icnt=1;;
     850UGRD) ffd=u850;ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=85000;icnt=1;;
     700UGRD) ffd=u700;ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=70000;icnt=1;;
     500UGRD) ffd=u500;ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=50000;icnt=1;;
     250UGRD) ffd=u250;ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=25000;icnt=1;;
     200UGRD) ffd=u200;ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=20000;icnt=1;;
     100UGRD) ffd=u100;ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=10000;icnt=1;;
      50UGRD) ffd=u50; ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=5000; icnt=1;;
      10UGRD) ffd=u10; ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=1000; icnt=1;;

    1000VGRD) ffd=v1000;ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=100000;icnt=1;;
     925VGRD) ffd=v925;ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=92500;icnt=1;;
     850VGRD) ffd=v850;ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=85000;icnt=1;;
     700VGRD) ffd=v700;ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=70000;icnt=1;;
     500VGRD) ffd=v500;ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=50000;icnt=1;;
     250VGRD) ffd=v250;ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=25000;icnt=1;;
     200VGRD) ffd=v200;ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=20000;icnt=1;;
     100VGRD) ffd=v100;ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=10000;icnt=1;;
      50VGRD) ffd=v50; ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=5000; icnt=1;;
      10VGRD) ffd=v10; ipdn=1;ipd1=2;ipd2=3;ipd10=100;ipd11=0;ipd12=1000; icnt=1;;

        TMAX) ffd=t2max;ipdn=11;ipd1=0;ipd2=4;ipd10=103;ipd11=0;ipd12=2;icnt=1;;
        TMIN) ffd=t2min;ipdn=11;ipd1=0;ipd2=5;ipd10=103;ipd11=0;ipd12=2;icnt=1;;
       PRMSL) ffd=prmsl;ipdn=1;ipd1=3;ipd2=1;ipd10=101;ipd11=0;ipd12=0;icnt=1;;
        PRES) ffd=pres; ipdn=1;ipd1=3;ipd2=0;ipd10=1;  ipd11=0;ipd12=0;icnt=1;;
     10MUGRD) ffd=u10m; ipdn=1;ipd1=2;ipd2=2;ipd10=103;ipd11=0;ipd12=10;icnt=1;;
     10MVGRD) ffd=v10m; ipdn=1;ipd1=2;ipd2=3;ipd10=103;ipd11=0;ipd12=10;icnt=1;;
       2MTMP) ffd=t2m;  ipdn=1;ipd1=0;ipd2=0;ipd10=103;ipd11=0;ipd12=2;icnt=1;;
    ULWRFsfc) ffd=ulwrfsfc;ipdn=11;ipd1=5;ipd2=193;ipd10=1;ipd11=0;ipd12=0;icnt=1;;
    ULWRFtop) ffd=ulwrftop;ipdn=11;ipd1=5;ipd2=193;ipd10=8;ipd11=0;ipd12=0;icnt=1;;
     850VVEL) ffd=vvel; ipdn=1;ipd1=2;ipd2=8;ipd10=100;ipd11=0;ipd12=85000;icnt=1;;
        2MRH) ffd=rh2m; ipdn=1;ipd1=1;ipd2=1;ipd10=103;ipd11=0;ipd12=2;icnt=1;;
       2MDPT) ffd=dpt2m;ipdn=1;ipd1=0;ipd2=6;ipd10=103;ipd11=0;ipd12=2;icnt=1;;
     10MWSPD) ffd=wspd10m; ipdn=1;ipd1=2;ipd2=1;ipd10=103;ipd11=0;ipd12=10;icnt=2;;

    esac

    if [ "$ffd" == "dummy" ]; then
      echo " #### attention: variable $cfield is not in the list"
    else
      (( nvar = nvar + 1 ))
      echo "ffd($nvar)='$ffd',ipdn($nvar)=$ipdn,mmod($nvar)=$icnt," >>namin.varlist
      echo "ipd1($nvar)=$ipd1,ipd2($nvar)=$ipd2,ipd10($nvar)=$ipd10,ipd11($nvar)=$ipd11,ipd12($nvar)=$ipd12," >>namin.varlist
    fi

  done

  echo "nvar=$nvar," >>namin.varlist
  echo " /" >>namin.varlist

fi

###################################
# start loop for forecast lead time
###################################

for nfhrs in $hourlist; do

  if [ -s namin.prob.$nfhrs ]; then
    rm namin.prob.$nfhrs
  fi

  echo " &namens" >>namin.prob.$nfhrs

  ifile=0
  ifile_cmconly=0

  if [ "$IFNAEFS" = "YES" ]; then
   pidswitch=1
   ifdebias=1
  fi

  if [ "$IFCMCE" = "YES" ]; then
   ifdebias=1
  fi

##############################
# input NCEP Ensemble forecast
##############################

  if [ "$IFNAEFS" = "YES" -o  "$IFGEFS" = "YES" ]; then
    for mem in ${memberlist_ncep}; do
      ifile_ncep=$COMINNCEP/ge${mem}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}
      if [ -s $ifile_ncep ]; then
        (( ifile = ifile + 1 ))
        iskip=1
        if [ "$mem" = "c00" ]; then
          iskip=0
        fi
        echo " cfipg($ifile)='$ifile_ncep'," >>namin.prob.$nfhrs
        echo " iskip($ifile)=${iskip}," >>namin.prob.$nfhrs
      fi
    done
  fi

  iall_cmc=0

  if [ "$ifile" = "0" ]; then
     iall_cmc=1
  fi

##############################
#  input CMC Ensemble forecast
##############################

  if [ "$IFNAEFS" = "YES" -o  "$IFCMCE" = "YES" ]; then

    for mem in ${memberlist_cmc}; do

      cmcmem=`echo $mem | cut -c2-3`

#     if [ $nfhrs -le 99 ];then
#       ifile_cmc=${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P0${nfhrs}_0${cmcmem}.grib2
#       if [ $nfhrs -eq 00 ]; then
#         ifile_cmc=${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P000_0${cmcmem}.grib2
#       fi
#     else
#     fi

      ifile_cmc=${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P${nfhrs}_0${cmcmem}.grib2

      if [ -s $COMINCMC/${ifile_cmc} ]; then
        cp $COMINCMC/${ifile_cmc} .
        chmod 755 $ifile_cmc
      fi

      if [ "$IFCMCRAWRH" = "YES" ]; then
#       if [ $nfhrs -le 99 ];then
#         rawfile=${PDY}${cyc}_CMC_naefs_latlon0p5x0p5_P0${nfhrs}_0${cmcmem}.grib2
#         if [ $nfhrs -eq 00 ]; then
#           rawfile=${PDY}${cyc}_CMC_naefs_latlon0p5x0p5_P000_0${cmcmem}.grib2
#         fi
#       else
#         rawfile=${PDY}${cyc}_CMC_naefs_latlon0p5x0p5_P${nfhrs}_0${cmcmem}.grib2
#       fi

        rawfile=${PDY}${cyc}_CMC_naefs_hr_latlon0p5x0p5_P${nfhrs}_0${cmcmem}.grib2
#       ifile_cmcraw=$DCOM_CMC/$PDY/wgrbbul/cmcens_gb2/$rawfile
        ifile_cmcraw=$DCOM/$PDY/wgrbbul/cmcens_gb2/$rawfile
        if [ -s $ifile_cmcraw ]; then
          $WGRIB2 -match ":RH:" -match "2 m" $ifile_cmcraw -append -grib $ifile_cmc
        fi
      fi

      if [ -s $ifile_cmc ]; then
        (( ifile = ifile + 1 ))
        (( ifile_cmconly = ifile_cmconly + 1 ))
        iskip=2
        if [ "$mem" = "c00" ]; then
          iskip=0
        fi
        echo " cfipg($ifile)='${ifile_cmc}'," >>namin.prob.$nfhrs
        echo " iskip($ifile)=${iskip}," >>namin.prob.$nfhrs
      fi

    done

    iall_fnmoc=0

    if [ "$ifile" = "0" ]; then
      iall_fnmoc=1
    fi

########################################################################
#  input CMC 2m temperature 6h ago for tmax and tmin forecast adjustment 
########################################################################
    if [ $nfhrs -ge 06 ]; then
      nfhrsm06=`expr $nfhrs - 06`

      if [ $nfhrsm06 -le 09 ]; then
        ifile_t2m_m06_cmc=cmc_enspost.t${cyc}z.pgrb2a.0p50_bcf0${nfhrsm06}
      else
        ifile_t2m_m06_cmc=cmc_enspost.t${cyc}z.pgrb2a.0p50_bcf${nfhrsm06}
      fi
      >$ifile_t2m_m06_cmc

      for mem in ${memberlist_cmc}; do

        cmcmem=`echo $mem | cut -c2-3`

        if [ $nfhrsm06 -le 99 -a $nfhrsm06 -ge 10 ]; then
          tmpfile=${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P0${nfhrsm06}_0${cmcmem}.grib2
        elif [ $nfhrsm06 -lt 10 -a $nfhrsm06 -gt 0 ]; then
          tmpfile=${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P00${nfhrsm06}_0${cmcmem}.grib2
        elif [ $nfhrsm06 -eq 00 ]; then
          tmpfile=${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P000_0${cmcmem}.grib2
        else
          tmpfile=${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P${nfhrsm06}_0${cmcmem}.grib2
        fi

        ifile_cmcm06=$COMINCMC/${tmpfile}

        if [ -s $ifile_cmcm06 ]; then
          $WGRIB2 -match ":TMP:" -match "2 m" $ifile_cmcm06 -append -grib $ifile_t2m_m06_cmc
        fi
      done

    fi     

###########################################################################
# CMC and NCEP analysis difference input, first step is to judge valid time
###########################################################################

    cyc_verf=`$NDATE +$nfhrs $PDY$cyc | cut -c9-10`
    ifile_anldiff_cmc=ncepcmc_glbanl.t${cyc_verf}z.pgrb2a.0p50_mdf000

    if [ -s $COM_CMCANL/gefs.$PDYm1/${cyc_verf}/pgrb2ap5/$ifile_anldiff_cmc ]; then
      cp $COM_CMCANL/gefs.$PDYm1/${cyc_verf}/pgrb2ap5/$ifile_anldiff_cmc  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm2/${cyc_verf}/pgrb2ap5/$ifile_anldiff_cmc ]; then
      cp $COM_CMCANL/gefs.$PDYm2/${cyc_verf}/pgrb2ap5/$ifile_anldiff_cmc  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm3/${cyc_verf}/pgrb2ap5/$ifile_anldiff_cmc ]; then
      cp $COM_CMCANL/gefs.$PDYm3/${cyc_verf}/pgrb2ap5/$ifile_anldiff_cmc  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm4/${cyc_verf}/pgrb2ap5/$ifile_anldiff_cmc ]; then
      cp $COM_CMCANL/gefs.$PDYm4/${cyc_verf}/pgrb2ap5/$ifile_anldiff_cmc  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm5/${cyc_verf}/pgrb2ap5/$ifile_anldiff_cmc ]; then
      cp $COM_CMCANL/gefs.$PDYm5/${cyc_verf}/pgrb2ap5/$ifile_anldiff_cmc  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm6/${cyc_verf}/pgrb2ap5/$ifile_anldiff_cmc ]; then
      cp $COM_CMCANL/gefs.$PDYm6/${cyc_verf}/pgrb2ap5/$ifile_anldiff_cmc  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm7/${cyc_verf}/pgrb2ap5/$ifile_anldiff_cmc ]; then
      cp $COM_CMCANL/gefs.$PDYm7/${cyc_verf}/pgrb2ap5/$ifile_anldiff_cmc  . 
    fi

#################################################
# CMC and NCEP analysis difference (6h ago) input
#################################################

    if [ $nfhrs -ge 06 ]; then
      pdy_verf=`$NDATE +$nfhrs $PDY$cyc`
      cyc_verfm06=`$NDATE -06 $pdy_verf | cut -c9-10`
      ifile_anldiff_cmc_m06=ncepcmc_glbanl.t${cyc_verfm06}z.pgrb2a.0p50_mdf000

      if [ -s $COM_CMCANL/gefs.$PDYm1/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_cmc_m06 ]; then
        cp $COM_CMCANL/gefs.$PDYm1/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_cmc_m06  . 
      elif [ -s $COM_CMCANL/gefs.$PDYm2/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_cmc_m06 ]; then
        cp $COM_CMCANL/gefs.$PDYm2/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_cmc_m06  . 
      elif [ -s $COM_CMCANL/gefs.$PDYm3/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_cmc_m06 ]; then
        cp $COM_CMCANL/gefs.$PDYm3/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_cmc_m06  . 
      elif [ -s $COM_CMCANL/gefs.$PDYm4/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_cmc_m06 ]; then
        cp $COM_CMCANL/gefs.$PDYm4/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_cmc_m06  . 
      elif [ -s $COM_CMCANL/gefs.$PDYm5/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_cmc_m06 ]; then
        cp $COM_CMCANL/gefs.$PDYm5/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_cmc_m06  . 
      elif [ -s $COM_CMCANL/gefs.$PDYm6/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_cmc_m06 ]; then
        cp $COM_CMCANL/gefs.$PDYm6/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_cmc_m06  . 
      elif [ -s $COM_CMCANL/gefs.$PDYm7/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_cmc_m06 ]; then
        cp $COM_CMCANL/gefs.$PDYm7/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_cmc_m06  . 
      fi
    fi

  fi

################################
#  input FNMOC Ensemble forecast
################################

  if [ "$IFNAEFS" = "YES" ]; then

    for mem in ${memberlist_fnmoc}; do
      ifile_fnmoc=$COMINFENS/fnmoc_ge${mem}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}
      if [ -s $ifile_fnmoc ]; then
        (( ifile = ifile + 1 ))
        iskip=3
        echo " cfipg($ifile)='$COMINFENS/fnmoc_ge${mem}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}'," >>namin.prob.$nfhrs
        echo " iskip($ifile)=${iskip}," >>namin.prob.$nfhrs
      fi
    done

##########################################################################
#  input FNMOC 2m temperature 6h ago for tmax and tmin forecast adjustment 
##########################################################################
    if [ $nfhrs -ge 06 ]; then
      nfhrsm06=`expr $nfhrs - 06`
      if [ $nfhrsm06 -le 09 ]; then
        ifile_t2m_m06_fnmoc=fnmoc_enspost.t${cyc}z.pgrb2a.0p50_bcf0${nfhrsm06}
      else
        ifile_t2m_m06_fnmoc=fnmoc_enspost.t${cyc}z.pgrb2a.0p50_bcf${nfhrsm06}
      fi
      >$ifile_t2m_m06_fnmoc

      for mem in ${memberlist_fnmoc}; do
        if [ $nfhrsm06 -le 09 ]; then
          ifile_fnmocm06=$COMINFENS/fnmoc_ge${mem}.t${cyc}z.pgrb2a.0p50_bcf0$nfhrsm06
          if [ $nfhrsm06 -eq 00 ]; then
            fensmem=`echo $mem | cut -c2-3`
            name_file=ENSEMBLE.MET.fcst_et0${fensmem}.000.${PDY}${cyc}
#           ifile_fnmocm06=$DCOM_CMC/$PDY/wgrbbul/fnmocens_gb2/$name_file
            ifile_fnmocm06=$DCOM/$PDY/wgrbbul/fnmocens_gb2/$name_file
            echo $ifile_fnmocm06
          fi   
        else
          ifile_fnmocm06=$COMINFENS/fnmoc_ge${mem}.t${cyc}z.pgrb2a.0p50_bcf$nfhrsm06
        fi
        if [ -s $ifile_fnmocm06 ]; then
          $WGRIB2 -match ":TMP:" -match "2 m" $ifile_fnmocm06 -append -grib $ifile_t2m_m06_fnmoc
        fi
      done
    fi     

#############################################################################
# FNMOC and NCEP analysis difference input, first step is to judge valid time
#############################################################################

    cyc_verf=`$NDATE +$nfhrs $PDY$cyc | cut -c9-10`
    ifile_anldiff_fnmoc=ncepfnmoc_glbanl.t${cyc_verf}z.pgrb2a.0p50_mdf000 

    if [ -s $COM_FENSANL/gefs.$PDYm1/${cyc_verf}/pgrb2ap5/$ifile_anldiff_fnmoc ]; then
      cp $COM_FENSANL/gefs.$PDYm1/${cyc_verf}/pgrb2ap5/$ifile_anldiff_fnmoc  . 
    elif [ -s $COM_FENSANL/gefs.$PDYm2/${cyc_verf}/pgrb2ap5/$ifile_anldiff_fnmoc ]; then
      cp $COM_FENSANL/gefs.$PDYm2/${cyc_verf}/pgrb2ap5/$ifile_anldiff_fnmoc  . 
    elif [ -s $COM_FENSANL/gefs.$PDYm3/${cyc_verf}/pgrb2ap5/$ifile_anldiff_fnmoc ]; then
      cp $COM_FENSANL/gefs.$PDYm3/${cyc_verf}/pgrb2ap5/$ifile_anldiff_fnmoc  . 
    elif [ -s $COM_FENSANL/gefs.$PDYm4/${cyc_verf}/pgrb2ap5/$ifile_anldiff_fnmoc ]; then
      cp $COM_FENSANL/gefs.$PDYm4/${cyc_verf}/pgrb2ap5/$ifile_anldiff_fnmoc  . 
    elif [ -s $COM_FENSANL/gefs.$PDYm5/${cyc_verf}/pgrb2ap5/$ifile_anldiff_fnmoc ]; then
      cp $COM_FENSANL/gefs.$PDYm5/${cyc_verf}/pgrb2ap5/$ifile_anldiff_fnmoc  . 
    elif [ -s $COM_FENSANL/gefs.$PDYm6/${cyc_verf}/pgrb2ap5/$ifile_anldiff_fnmoc ]; then
      cp $COM_FENSANL/gefs.$PDYm6/${cyc_verf}/pgrb2ap5/$ifile_anldiff_fnmoc  . 
    elif [ -s $COM_FENSANL/gefs.$PDYm7/${cyc_verf}/pgrb2ap5/$ifile_anldiff_fnmoc ]; then
      cp $COM_FENSANL/gefs.$PDYm7/${cyc_verf}/pgrb2ap5/$ifile_anldiff_fnmoc  . 
    fi

###################################################
# FNMOC and NCEP analysis difference (6h ago) input
###################################################

    if [ $nfhrs -ge 06 ]; then
      pdy_verf=`$NDATE +$nfhrs $PDY$cyc`
      cyc_verfm06=`$NDATE -06 $pdy_verf | cut -c9-10`
      ifile_anldiff_fnmoc_m06=ncepfnmoc_glbanl.t${cyc_verfm06}z.pgrb2a.0p50_mdf000

      if [ -s $COM_FENSANL/gefs.$PDYm1/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_fnmoc_m06 ]; then
        cp $COM_FENSANL/gefs.$PDYm1/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_fnmoc_m06  . 
      elif [ -s $COM_FENSANL/gefs.$PDYm2/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_fnmoc_m06 ]; then
        cp $COM_FENSANL/gefs.$PDYm2/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_fnmoc_m06  . 
      elif [ -s $COM_FENSANL/gefs.$PDYm3/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_fnmoc_m06 ]; then
        cp $COM_FENSANL/gefs.$PDYm3/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_fnmoc_m06  . 
      elif [ -s $COM_FENSANL/gefs.$PDYm4/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_fnmoc_m06 ]; then
        cp $COM_FENSANL/gefs.$PDYm4/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_fnmoc_m06  . 
      elif [ -s $COM_FENSANL/gefs.$PDYm5/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_fnmoc_m06 ]; then
        cp $COM_FENSANL/gefs.$PDYm5/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_fnmoc_m06  . 
      elif [ -s $COM_FENSANL/gefs.$PDYm6/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_fnmoc_m06 ]; then
        cp $COM_FENSANL/gefs.$PDYm6/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_fnmoc_m06  . 
      elif [ -s $COM_FENSANL/gefs.$PDYm7/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_fnmoc_m06 ]; then
        cp $COM_FENSANL/gefs.$PDYm7/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_fnmoc_m06  . 
      fi
    fi

  fi

####################
# set up input files 
####################

  echo " pidswitch=${pidswitch}," >>namin.prob.$nfhrs
  echo " nfiles=${ifile}," >>namin.prob.$nfhrs
  echo " ifdebias=${ifdebias}," >>namin.prob.$nfhrs
  echo " iall_cmc=${iall_cmc}," >>namin.prob.$nfhrs
  echo " iall_fnmoc=${iall_fnmoc}," >>namin.prob.$nfhrs

  if [ "$IFCMCE" = "YES" ]; then
    echo " cfipg1='${ifile_t2m_m06_cmc}'," >>namin.prob.$nfhrs
    echo " cfipg2='${ifile_anldiff_cmc}'," >>namin.prob.$nfhrs
    echo " cfipg3='${ifile_anldiff_cmc_m06}'," >>namin.prob.$nfhrs
  fi

  if [ "$IFNAEFS" = "YES" ]; then
    echo " cfipg1='${ifile_t2m_m06_cmc}'," >>namin.prob.$nfhrs
    echo " cfipg2='${ifile_anldiff_cmc}'," >>namin.prob.$nfhrs
    echo " cfipg3='${ifile_anldiff_cmc_m06}'," >>namin.prob.$nfhrs

    echo " cfipg4='${ifile_t2m_m06_fnmoc}'," >>namin.prob.$nfhrs
    echo " cfipg5='${ifile_anldiff_fnmoc}'," >>namin.prob.$nfhrs
    echo " cfipg6='${ifile_anldiff_fnmoc_m06}'," >>namin.prob.$nfhrs
  fi

  echo " ifhr=$nfhrs," >>namin.prob.$nfhrs

#####################
# set up output files 
#####################

  echo " cfopg1='ge10pt.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}'," >>namin.prob.$nfhrs
  echo " cfopg2='ge90pt.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}'," >>namin.prob.$nfhrs
  echo " cfopg3='ge50pt.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}'," >>namin.prob.$nfhrs
  echo " cfopg4='geavg.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}'," >>namin.prob.$nfhrs
  echo " cfopg5='gespr.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}'," >>namin.prob.$nfhrs
  echo " cfopg6='gemode.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}'," >>namin.prob.$nfhrs

  echo " /" >>namin.prob.$nfhrs

  cat namin.varlist >>namin.prob.$nfhrs

  if [ $cyc -eq 00 -o $cyc -eq 12 ]; then
    if [ "$IFNAEFS" = "YES" -a $ifile_cmconly -eq 0 -a $ifile -ne 0 ]; then
      echo "Warning!!! NAEFS has only GEFS input for fcst " $nfhrs
    fi
  fi

  if [ $ifile -eq 0 ]; then
    echo "FATAL ERROR: Input ensemble files not available for fcst hr " $nfhrs
    export err=1; err_chk
  fi

  startmsg
  $EXECnaefs/naefs_bc_probability <namin.prob.$nfhrs > $pgmout.${nfhrs}_prob  2> errfile
  export err=$?;err_chk

done

set +x
echo " "
echo "Leaving sub script naefs_bc_probability.sh"
echo " "
set -x

