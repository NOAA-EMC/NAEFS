###############################################################################################
# Script:   cmce_adjust_tmaxmin_alaska.sh 
# Abstract: Use accumulated NCEP and CMC analysis difference to adjust CMC T2m, Tmax and Tmin
#           for each member, which will be used for downscaled tmax & tmin
# Author:   Bo Cui 
# History:  Oct 2013 - First implementation of this new script 
#           Jun 2015 - NAEFS version 5 modified for 3km products
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

pgm=cmce_adjust_tmaxmin
pgmout=output_adjustcmc

############################################################
# define if removing analyis difference between CMC and NCEP
# 0 = don't remove difference from CMC ensemble forecast
# 1 = remove difference from CMC ensemble forecast
############################################################

ifdebias=1

for nfhrs in $hourlist; do

  if [ -s namin.adjustcmc.$nfhrs ]; then
    rm namin.adjustcmc.$nfhrs
  fi

  echo " &namens" >>namin.adjustcmc.$nfhrs

  ifile=0

##############################
#  input CMC Ensemble forecast
##############################

  for mem in ${memberlist_cmc}; do
    cmcmem=`echo $mem | cut -c2-3`
    ifile_cmc=$COMINCMC/${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P${nfhrs}_0${cmcmem}.grib2
    if [ -s $ifile_cmc ]; then
      (( ifile = ifile + 1 ))
      iskip=-1
      if [ "$mem" = "c00" ]; then
        iskip=0
      fi
      echo " cfipg($ifile)='${ifile_cmc}'," >>namin.adjustcmc.$nfhrs
      echo " iskip($ifile)=${iskip}," >>namin.adjustcmc.$nfhrs
    fi
  done

########################################################################
#  input CMC 2m temperature 6h ago for tmax and tmin forecast adjustment 
########################################################################

  if [ $nfhrs -ge 06 ]; then
    nfhrsm06=`expr $nfhrs - 06`
    if [ $nfhrsm06 -le 09 ]; then
      ifile_t2m_m06=cmc_enspost.t${cyc}z.pgrb2a.0p50_bcf0${nfhrsm06}
    else
      ifile_t2m_m06=cmc_enspost.t${cyc}z.pgrb2a.0p50_bcf${nfhrsm06}
    fi
    >$ifile_t2m_m06

    for mem in ${memberlist_cmc}; do
      cmcmem=`echo $mem | cut -c2-3`
      if [ $nfhrsm06 -le 99 -a $nfhrsm06 -ge 10 ]; then
        ifile_cmcm06=$COMINCMC/${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P0${nfhrsm06}_0${cmcmem}.grib2
      elif [ $nfhrsm06 -lt 10 -a $nfhrsm06 -gt 0 ]; then
        ifile_cmcm06=$COMINCMC/${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P00${nfhrsm06}_0${cmcmem}.grib2
      elif [ $nfhrsm06 -eq 00 ];then
        ifile_cmcm06=$COMINCMC/${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P000_0${cmcmem}.grib2
      else
        ifile_cmcm06=$COMINCMC/${PDY}${cyc}_CMC_naefsbc_hr_latlon0p5x0p5_P${nfhrsm06}_0${cmcmem}.grib2
      fi
      if [ -s $ifile_cmcm06 ]; then
        $WGRIB2 -match ":TMP:" -match "2 m" $ifile_cmcm06 -append -grib $ifile_t2m_m06    
      else
        echo "File $ifile_cmcm06 is missing"
      fi
    done

  fi     

###########################################################################
# CMC and NCEP analysis difference input, first step is to judge valid time
###########################################################################

  cyc_verf=`$NDATE +$nfhrs $PDY$cyc | cut -c9-10`
  ifile_anldiff=ncepcmc_glbanl.t${cyc_verf}z.pgrb2a.0p50_mdf000

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

#################################################
# CMC and NCEP analysis difference (6h ago) input
#################################################

  if [ $nfhrs -ge 06 ]; then
    pdy_verf=`$NDATE +$nfhrs $PDY$cyc`
    cyc_verfm06=`$NDATE -6 $pdy_verf | cut -c9-10`
    ifile_anldiff_m06=ncepcmc_glbanl.t${cyc_verfm06}z.pgrb2a.0p50_mdf000

    if [ -s $COM_CMCANL/gefs.$PDYm1/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_m06 ]; then
      cp $COM_CMCANL/gefs.$PDYm1/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_m06  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm2/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_m06 ]; then
      cp $COM_CMCANL/gefs.$PDYm2/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_m06  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm3/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_m06 ]; then
      cp $COM_CMCANL/gefs.$PDYm3/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_m06  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm4/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_m06 ]; then
      cp $COM_CMCANL/gefs.$PDYm4/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_m06  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm5/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_m06 ]; then
      cp $COM_CMCANL/gefs.$PDYm5/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_m06  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm6/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_m06 ]; then
      cp $COM_CMCANL/gefs.$PDYm6/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_m06  . 
    elif [ -s $COM_CMCANL/gefs.$PDYm7/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_m06 ]; then
      cp $COM_CMCANL/gefs.$PDYm7/${cyc_verfm06}/pgrb2ap5/$ifile_anldiff_m06  . 
    fi
  fi

####################
# set up input files 
####################

  echo " nfiles=${ifile}," >>namin.adjustcmc.$nfhrs
  echo " ifdebias=${ifdebias}," >>namin.adjustcmc.$nfhrs

  echo " cfipg1='${ifile_t2m_m06}'," >>namin.adjustcmc.$nfhrs
  echo " cfipg2='${ifile_anldiff}'," >>namin.adjustcmc.$nfhrs
  echo " cfipg3='${ifile_anldiff_m06}'," >>namin.adjustcmc.$nfhrs
  echo " ifhr=$nfhrs," >>namin.adjustcmc.$nfhrs

#####################
# set up output files 
#####################

  echo " cfopg1='cmce.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_temp'," >>namin.adjustcmc.$nfhrs

  echo " /" >>namin.adjustcmc.$nfhrs

done

if [ -s poescript_adjust ]; then rm poescript_adjust; fi

for nfhrs in $hourlist; do
  echo "$EXECrtma/$pgm <namin.adjustcmc.$nfhrs > $pgmout.${nfhrs} 2> errfile" >>poescript_adjust
done

chmod +x poescript_adjust 
startmsg
$APRUN poescript_adjust
export err=$?; err_chk

wait

set +x
echo " "
echo "Leaving sub script cmce_adjust_tmaxmin_alaska.sh"
echo " "
set -x

