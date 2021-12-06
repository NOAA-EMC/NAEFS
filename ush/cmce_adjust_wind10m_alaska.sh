#!/bin/sh
###############################################################################################
# Script:   cmce_adjust_wind10m_alaska.sh 
# Abstract: Use accumulated NCEP and CMC analysis difference to adjust CMC 10m wind u and v of
#           each member, which will be used to get downscaled wind speed and direction
#           for variable 10m wind u and v
# Author:   Bo Cui 
# History:  Octor 2013 - First implementation of this new script 
#           June  2015 - NAEFS version 5 modified for 3km products
###############################################################################################

set -x
########################################
#  define ensemble members and lead time
########################################

#hourlist=" 00  06  12  18  24  30  36  42  48  54  60  66  72  78  84  90  96 \
#          102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
#          204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
#          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

#memberlist_cmc="p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"

##############################################
# define exec variable, and entry grib utility
##############################################

pgm=cmce_adjust_wind10m
pgmout=output_adjustcmc

############################################################
# define if removing analyis difference between CMC and NCEP
# 0 = don't remove difference from CMC ensemble forecast
# 1 = remove difference from CMC ensemble forecast
############################################################

ifdebias=1

for nfhrs in $hourlist; do

  for mem in ${memberlist_cmc}; do

    cmcmem=`echo $mem | cut -c2-3`

    if [ -s namin.adjustcmc.$nfhrs.$mem ]; then
      rm namin.adjustcmc.$nfhrs.$mem
    fi

    echo " &namens" >>namin.adjustcmc.$nfhrs.$mem

    ifile=0

##############################
#  input CMC Ensemble forecast
##############################

    ifile_cmc=$COMINCMC/${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P${nfhrs}_0${cmcmem}.grib2

    if [ -s $ifile_cmc ]; then
      (( ifile = ifile + 1 ))
      iskip=-1
      if [ "$mem" = "c00" ]; then
        iskip=0
      fi
      echo " cfipg($ifile)='${ifile_cmc}'," >>namin.adjustcmc.$nfhrs.$mem
      echo " iskip($ifile)=${iskip}," >>namin.adjustcmc.$nfhrs.$mem
    fi

###########################################################################
# CMC and NCEP analysis difference input, first step is to judge valid time
###########################################################################

    cyc_verf=`$NDATE +$nfhrs $PDY$cyc | cut -c9-10`

    ifile_anldiff=ncepcmc_glbanl.t${cyc_verf}z.pgrb2a.0p50_mdf00

    if [ -s $COM_CMCANL/gefs.$PDYm1/${cyc_verf}/pgrb2ap5/$ifile_anldiff ]; then
      cp $COM_CMCANL/gefs.$PDYm1/${cyc_verf}/pgrb2ap5/$ifile_anldiff  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm2/${cyc_verf}/pgrb2ap5/$ifile_anldiff ]; then
      cp $COM_CMCANL/gefs.$PDYm2/${cyc_verf}/pgrb2ap5/$ifile_anldiff  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm3/${cyc_verf}/pgrb2ap5/$ifile_anldiff ]; then
      cp $COM_CMCANL/gefs.$PDYm3/${cyc_verf}/pgrb2ap5/$ifile_anldiff  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm4/${cyc_verf}/pgrb2ap5/$ifile_anldiff ]; then
      cp $COM_CMCANL/gefs.$PDYm4/${cyc_verf}/pgrb2ap5/$ifile_anldiff  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm5/${cyc_verf}/pgrb2ap5/$ifile_anldiff ]; then
      cp $COM_CMCANL/gefs.$PDYm5/${cyc_verf}/pgrb2ap5/$ifile_anldiff  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm6/${cyc_verf}/pgrb2ap5/$ifile_anldiff ]; then
      cp $COM_CMCANL/gefs.$PDYm6/${cyc_verf}/pgrb2ap5/$ifile_anldiff  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm7/${cyc_verf}/pgrb2ap5/$ifile_anldiff ]; then
      cp $COM_CMCANL/gefs.$PDYm7/${cyc_verf}/pgrb2ap5/$ifile_anldiff  . 
    fi

####################
# set up input files 
####################

    echo " nfiles=${ifile}," >>namin.adjustcmc.$nfhrs.$mem
    echo " ifdebias=${ifdebias}," >>namin.adjustcmc.$nfhrs.$mem
    echo " cfipg1='${ifile_anldiff}'," >>namin.adjustcmc.$nfhrs.$mem

#####################
# set up output files 
#####################

    echo " cfopg1='cmc_ge${mem}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_temp'," >>namin.adjustcmc.$nfhrs.$mem

    if [ -s cmc_ge${mem}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_temp ]; then
      rm cmc_ge${mem}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_temp
    fi

    echo " /" >>namin.adjustcmc.$nfhrs.$mem

  done 

done

for mem in ${memberlist_cmc}; do
  if [ -s poescript_$mem ]; then
    rm poescript_$mem
  fi
  for nfhrs in $hourlist; do
    echo "$EXECrtma/$pgm <namin.adjustcmc.$nfhrs.$mem > $pgmout.${nfhrs}.$mem" >> poescript_$mem
  done
  chmod +x poescript_$mem 
  startmsg
  $APRUN poescript_$mem
  export err=$?; err_chk
  wait
done

set +x
echo " "
echo "Leaving sub script cmce_adjust_wind10m.sh"
echo " "
set -x

