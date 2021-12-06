#!/bin/sh
########################### NDGD PRODUCTS #################################################
echo "------------------------------------------------------------------------------------"
echo "Apply Downscaling Method to Generat Ensemble Forecast on NDGD Grid for Conus Region"
echo "Script:  exnaefs_dvrtma2p5_prob_avgspr_conus.sh.ecf "
echo "Author:  Bo Cui (Bo.Cui)"
echo "History: October 2013 - First implementation of this new script."
echo "         August  2015 - Modified for 5km and 2.5km CONUS"
echo "------------------------------------------------------------------------------------"
###########################################################################################

export PS4='${PMI_FORK_RANK}: $SECONDS + '
set -x

### To submit this job for T00Z, T06Z T12Z and T18Z, four cycles per day

### need pass the values of PDY, cyc, DATA, COM_NCEP, COM_CMC, COMOUT

##############################################
# define exec variable, and entry grib utility
##############################################

export ENSDVRTMA=$USHrtma/dvrtma_debias_conus.sh           

########################################
#  define ensemble members and lead time
########################################

export hourlist="    003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 \
                 051 054 057 060 063 066 069 072 075 078 081 084 087 090 093 096 099 \
                 102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 \
                 153 156 159 162 165 168 171 174 177 180 183 186 189 192 198 204 \
                 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
                 306 312 318 324 330 336 342 348 354 360 366 372 378 384"

export memberlist_ncep="p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 \
                        p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"

export memberlist_cmc="p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 \
                       p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"

outlist_cmc="cmc_ge10pt cmc_ge50pt cmc_ge90pt cmc_gemode cmc_geavg cmc_gespr"
outlist_ncep="ge10pt ge50pt ge90pt gemode geavg gespr"
outlist_naefs="naefs_ge10pt naefs_ge50pt naefs_ge90pt naefs_gemode naefs_geavg naefs_gespr"

prodlist="ge10pt ge50pt ge90pt gemode geavg gespr"

if [ "$IFNAEFS" = "YES" ]; then
  export outlist=$outlist_naefs
fi

if [ "$IFGEFS" = "YES" ]; then
  export outlist=$outlist_ncep
fi

if [ "$IFCMCE" = "YES" ]; then
  export outlist=$outlist_cmc  
fi

################################################################################################
# downscale ensemble probability forecast, ensemble average & spread
# variable include: t2m, u10m, v10m, surface pressure, wind speed, wind direction, tmax and tmin
################################################################################################

$ENSDVRTMA     

#####################
# generate grib2 data
#####################

if [ "$SENDCOM" = "YES" ]; then

  #
  #  move downscaled products 2.5km conus in grib2 
  #

  if [ "$IFNAEFS" = "YES" ]; then
    for nfhrs in $hourlist; do
      for nens in $prodlist; do
        if [ -s poe_move.${nfhrs}.${nens} ]; then rm poe_move.${nfhrs}.${nens}; fi
        file_in=naefs_${nens}.t${cyc}z.ndgd2p5_conusf${nfhrs}.grib2_ext
        file_out=naefs.t${cyc}z.${nens}.f${nfhrs}.conus_ext_2p5.grib2
        echo "mv $file_in $COMOUT_GB2/$file_out" >>poe_move.${nfhrs}.${nens}
      done 
    done
  fi

  if [ "$IFGEFS" = "YES" ]; then
    for nfhrs in $hourlist; do
      for nens in $prodlist; do
        if [ -s poe_move.${nfhrs}.${nens} ]; then rm poe_move.${nfhrs}.${nens}; fi
        file_in=${nens}.t${cyc}z.ndgd2p5_conusf${nfhrs}.grib2_ext
        file_out=gefs.t${cyc}z.${nens}.f${nfhrs}.conus_ext_2p5.grib2
        echo "mv $file_in $COMOUT_GB2/$file_out" >>poe_move.${nfhrs}.${nens}
      done 
    done
  fi

  if [ -s poescript_move ]; then rm poescript_move; fi
  for nfhrs in $hourlist; do
    for nens in $prodlist; do
      chmod +x poe_move.${nfhrs}.${nens}
      echo "poe_move.${nfhrs}.${nens}" >>poescript_move
    done
  done

  chmod +x poescript_move
  startmsg
  $APRUN_post poescript_move

fi

#######################################################################
# Send NAEFS alerts only for the 00z and 12z late runs, since CMC data 
# is only available then; send GEFS for all cycles
#######################################################################

cd $DATA

if [ "$SENDDBN" = "YES" ]; then

  if [ "$IFNAEFS" = "YES" ]; then
    if [ "$cyc" = "00" -o "$cyc" = "12" ]; then
      if [ "$runlabel" = "late" ]; then
        for nfhrs in $hourlist; do
          for nens in $prodlist; do
            if [ -s poe_alert.${nfhrs}.${nens} ]; then rm poe_alert.${nfhrs}.${nens}; fi
            ifile=naefs.t${cyc}z.${nens}.f${nfhrs}.conus_ext_2p5.grib2    
            echo "$DBNROOT/bin/dbn_alert MODEL NAEFS_NDGD_GB2 $job $COMOUT_GB2/${ifile}" >>poe_alert.${nfhrs}.${nens}
          done
        done
        if [ -s poescript_alert ]; then rm poescript_alert; fi
        for nfhrs in $hourlist; do
          for nens in $prodlist; do
            chmod +x poe_alert.${nfhrs}.${nens}
            echo "poe_alert.${nfhrs}.${nens}" >>poescript_alert
          done
        done
        chmod +x poescript_alert
        startmsg
        $APRUN_post poescript_alert
      fi
    fi
  fi

  if [ "$IFGEFS" = "YES" ]; then
    for nfhrs in $hourlist; do
      for nens in $prodlist; do
        if [ -s poe_alert.${nfhrs}.${nens} ]; then rm poe_alert.${nfhrs}.${nens}; fi
        ifile=gefs.t${cyc}z.${nens}.f${nfhrs}.conus_ext_2p5.grib2    
        echo "$DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_NDGD_GB2 $job $COMOUT_GB2/${ifile}" >>poe_alert.${nfhrs}.${nens}
      done
    done
    if [ -s poescript_alert ]; then rm poescript_alert; fi
    for nfhrs in $hourlist; do
      for nens in $prodlist; do
        chmod +x poe_alert.${nfhrs}.${nens}
        echo "poe_alert.${nfhrs}.${nens}" >>poescript_alert
      done
    done
    chmod +x poescript_alert
    startmsg
    $APRUN_post poescript_alert
  fi

fi

msg="HAS COMPLETED NORMALLY!"
postmsg "$jlogfile" "$msg"

exit 0
