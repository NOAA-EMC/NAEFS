#############################################################################################
# Update Bias Estimation of Global Ensemble Forecast & GFS Forecast Daily
# AUTHOR: Bo Cui  (wx20cb)
# History: May 2006 - First implementation of this new script.
#          Dec 2006 - Modified script for GEFS system upgrade (20 members)
#          May 2007 - Modified script to include GFS forecast bias estimation
#          Jan 2008 - Add bias estimation calculation between NCEP & CMC analysis (CMC-NCEP)
#          Apr 2009 - Add 14 new variables for bias estimation 
#          Dec 2010 - Add 1 new variables for bias estimation 
#          Mar 2013 - Replace GRIB1 by GRIB2 
#          Jun 2015 - Add new variable (TCDC) 
#          Aug 2016 - Modified script for GEFS 0.5 degree data 
#                   - Add ush to calculate coefficient Daily for reforecast calibration
#                   - Add ush to calculate reforecast bias
#
#############################################################################################

### To submit this job for T00Z, T06Z T12Z and T18Z, four cycles per day

### need pass the values of PDY, CYC, DATA, COMIN, and COMOUT

export ENSBIAS_DECAY=$USHgefs/gefs_bias_decay.sh           
export ENSBIAS_DECAY_AVGEN=$USHgefs/gefs_bias_decay_avggen.sh           

export ENSBIAS_REFCST=$USHgefs/gefs_bias_reforecast.sh           
export ENSBIAS_COEFF=$USHgefs/gefs_bias_coeff.sh           
export ENSBIAS_COEFF_AVGGEN=$USHgefs/gefs_bias_coeff_avggen.sh           

export ENSBIAS_COMBINE=$USHgefs/gefs_bias_combine.sh           

####################################
# define exec variable and hourlist
####################################

if [ "$BIASMEM" = "YES" ]; then
export memberlist="c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"
fi

if [ "$BIASAVG" = "YES" ]; then
export memberlist="avg"
fi

if [ "$BIASC00" = "YES" ]; then
export memberlist="c00"
fi

if [ "$BIASGFS" = "YES" ]; then
export memberlist="gfs"
fi

if [ "$BIASAVG" = "YES" -a "$BIASGFS" = "YES" ]; then
export memberlist="avg gfs"
fi

if [ "$BIASAVG" = "YES" -a "$BIASGFS" = "YES" -a "$BIASC00" = "YES" ]; then
export memberlist="avg gfs c00"
fi

coefflist="abar fbar saabar sffbar sfabar coeff"

export hourlist="    003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 \
                 051 054 057 060 063 066 069 072 075 078 081 084 087 090 093 096 099 \
                 102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 \
                 153 156 159 162 165 168 171 174 177 180 183 186 189 192 198 204 \
                 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
                 306 312 318 324 330 336 342 348 354 360 366 372 378 384"

export hrlist_6hr="    006 012 018 024 030 036 042 048 054 060 066 072 078 084 090 096 \
                   102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
                   204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
                   306 312 318 324 330 336 342 348 354 360 366 372 378 384"

export hrlist_gfs="    006 012 018 024 030 036 042 048 054 060 066 072 078 084 090 096 \
                   102 108 114 120 126 132 138 144 150 156 162 168 174 180"

####################################################
# Step 1: Calculate decaying bias for each lead time
####################################################

if [ "$IF_REFCSTWITH" = "YES" -o "$IF_DECAYONLY" = "YES" ]; then
  $ENSBIAS_DECAY
  $ENSBIAS_DECAY_AVGEN
fi

###################################################
# Step 2: Calculate reforecast for each lead time
#         Calculate coefficience for each lead time
###################################################

if [ "$IF_REFCSTWITH" = "YES" -o "$IF_REFCSTONLY" = "YES" ]; then
   $ENSBIAS_REFCST
   $ENSBIAS_COEFF
   $ENSBIAS_COEFF_AVGGEN
fi

#####################################
# Save output files to com2 directory 
#####################################

if [ "$SENDCOM" = "YES" ]; then

  if [ "$IF_REFCSTWITH" = "YES" -o "$IF_DECAYONLY" = "YES" ]; then

    for nfhrs in $hourlist; do
      for nens in $memberlist; do
        file=$DATA/dir_decay/ge${nens}.t${cyc}z.pgrb2a.0p50_mef${nfhrs}
        if [ -s $file ]; then
          cp $file $COMOUT/
        fi
      done
    done

    file=$DATA/dir_decay/glbanl.t${cyc}z.pgrb2a.0p50_mdf000
    if [ -s $file ]; then
      mv $file $COMOUT_M1/
    fi

    file=$DATA/dir_decay/ncepcmc_glbanl.t${cyc}z.pgrb2a.0p50_mdf000
    if [ -s $file ]; then
      mv $file $COMOUT_M2/
    fi

  fi
  
  if [ "$IF_REFCSTWITH" = "YES" -o "$IF_REFCSTONLY" = "YES" ]; then

    for nfhrs in $hourlist; do
      for coeff in $coefflist; do
        file=dir_coeff/geavg.t${cyc}z.pgrb2a.0p50_${coeff}f${nfhrs}
        if [ -s $file ]; then
          cp $file $COMOUT
        fi    
      done
    done

  fi

fi

#################################
# Step 3: Calculate combined bias                      
#################################

$ENSBIAS_COMBINE

if [ "$SENDCOM" = "YES" ]; then
  for nfhrs in $hourlist; do
    file=$DATA/dir_combine/geavg.t${cyc}z.pgrb2a.0p50_mecomf${nfhrs}
    if [ -s $file ]; then
      mv $file $COMOUT/
    fi
  done
fi

msg="HAS COMPLETED NORMALLY!"
postmsg "$jlogfile" "$msg"

exit 0
