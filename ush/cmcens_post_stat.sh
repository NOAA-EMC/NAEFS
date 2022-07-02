#!/bin/sh
##############################################################
# Script: cmcens_post_stat.sh
# Abstract: this script generate CMC enspost and ensstat files
# Author: Bo Cui ---- Feb. 2017
###############################################################

set -x

################################
# step 1: generate enspost files
################################

varlpost="z1000 z500 u850 u200 v850 v200 t850 t2m rh700 prmsl u10m v10m \
          rain frzr icep snow prcp "

for var in $varlpost; do

  case $var in

  z1000) ffd=HGT:1000;; 
  z500)  ffd=HGT:500;;  
  u850)  ffd=UGRD:850;; 
  u200)  ffd=UGRD:200;; 
  v850)  ffd=VGRD:850;; 
  v200)  ffd=VGRD:200;; 
  t850)  ffd=TMP:850;; 
  t2m)   ffd="TMP:2 m";;  
  rh700) ffd=RH:700;;  
  prmsl) ffd=PRMSL:mean;;
  u10m)  ffd="UGRD:10 m above";;
  v10m)  ffd="VGRD:10 m above";;
  rain)  ffd=CRAIN:surface;;
  frzr)  ffd=CFRZR:surface;;
  icep)  ffd=CICEP:surface;;
  snow)  ffd=CSNOW:surface;;
  prcp)  ffd=APCP:surface;;

  esac

  if [ -s poe_${var}_enspostc ]; then
    rm poe_${var}_enspostc                  
  fi

  outfile=enspostc.t${cyc}z.${var}hr
  echo ">$outfile"                                                        >> poe_${var}_enspostc               
  for mem in $memberlist; do
    for nfhrs in $hourlist; do
      if [ "$var" = "frzr" -o "$var" = "rain" -o "$var" = "icep" -o "$var" = "snow" ]; then
        cmcmem=`echo $mem | cut -c2-3`
        tmpfile=$DATA/CMC_naefs_hr_latlon0p5x0p5_P${nfhrs}_0${cmcmem}_acc
        infile=cmc_ge${mem}.t${cyc}z.pgrb2a.0p50.f${nfhrs}_acc_$var          
        if [ -s $tmpfile ]; then
          echo "$WGRIB2 -set center 7 $tmpfile -grib $infile"             >> poe_${var}_enspostc 
          echo "$WGRIB2 -match \"${ffd}\" $infile -append -grib $outfile" >> poe_${var}_enspostc
        else
          echo "echo \" enspostc no file $tmpfile \""                     >> poe_${var}_enspostc
        fi
      else  
        infile=$COMOUT/cmc_ge${mem}.t${cyc}z.pgrb2a.0p50.f${nfhrs}
        if [ -s $infile ]; then
          echo "$WGRIB2 -match \"${ffd}\" $infile -append -grib $outfile" >> poe_${var}_enspostc
        else
          echo "echo \" enspostc no file $infile \""                      >> poe_${var}_enspostc
        fi
      fi
    done
  done

done

if [ -s poescript_enspostc ]; then
  rm poescript_enspostc          
fi

for var in $varlpost; do
  chmod +x poe_${var}_enspostc
  echo ". ./poe_${var}_enspostc" >>poescript_enspostc      
done

chmod +x poescript_enspostc    
startmsg
$APRUN_post poescript_enspostc    
export err=$?;err_chk
wait

################################
# step 2: generate ensstat files
################################

varlstat="z1000 z500 u850 u200 v850 v200 t850 t2m rh700 prmsl u10m v10m prcp"

for var in $varlstat; do

  case $var in

  z1000) ffd=HGT:1000;; 
  z500)  ffd=HGT:500;;  
  u850)  ffd=UGRD:850;; 
  u200)  ffd=UGRD:200;; 
  v850)  ffd=VGRD:850;; 
  v200)  ffd=VGRD:200;; 
  t850)  ffd=TMP:850;; 
  t2m)   ffd="TMP:2 m";;  
  rh700) ffd=RH:700;;  
  prmsl) ffd=PRMSL:mean;;
  u10m)  ffd="UGRD:10 m above";;
  v10m)  ffd="VGRD:10 m above";;
  rain)  ffd=CRAIN:surface;;
  frzr)  ffd=CFRZR:surface;;
  icep)  ffd=CICEP:surface;;
  snow)  ffd=CSNOW:surface;;
  prcp)  ffd=APCP:surface;;

  esac

  if [ -s poe_${var}_ensstat ]; then
    rm poe_${var}_ensstat                  
  fi

  outfile=ensstat.t${cyc}z.${var}hr
  echo ">$outfile"                                                    >> poe_${var}_ensstat               
  for nfhrs in $hourlist; do
    infile=$COMOUT/cmc_geavg.t${cyc}z.pgrb2a.0p50.f${nfhrs}
    if [ -s $infile ]; then
      echo "$WGRIB2 -match \"${ffd}\" $infile -append -grib $outfile" >> poe_${var}_ensstat
    else
      echo "echo \" ensstat no file $infile \""                       >> poe_${var}_ensstat 
    fi
    infile=$COMOUT/cmc_gespr.t${cyc}z.pgrb2a.0p50.f${nfhrs}
    if [ -s $infile ]; then
      echo "$WGRIB2 -match \"${ffd}\" $infile -append -grib $outfile" >> poe_${var}_ensstat
    else
      echo "echo \" ensstat no file $infile \""                       >> poe_${var}_ensstat 
    fi
  done

done

if [ -s poescript_ensstat ]; then
  rm poescript_ensstat          
fi

for var in $varlstat; do
  chmod +x poe_${var}_ensstat
  echo ". ./poe_${var}_ensstat" >>poescript_ensstat      
done

chmod +x poescript_ensstat    
startmsg
$APRUN_stat poescript_ensstat    
export err=$?;err_chk
wait

if [ $SENDCOM = "YES" ]; then
  for var in $varlpost; do
    outfile=enspostc.t${cyc}z.${var}hr
    cp $outfile $COMOUTenst/
  done
  for var in $varlstat; do
    outfile=ensstat.t${cyc}z.${var}hr
    cp $outfile $COMOUTenst/
  done
fi

set +x
echo " "
echo "Leaving sub script cmcens_post_stat.sh"
echo " "
set -x
