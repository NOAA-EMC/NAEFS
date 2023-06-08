#!/bin/sh
########################### NAEFS PRODUCTS ####################################
echo "------------------------------------------------"
echo "NAEFS products generation from combined NCEP/GEFS and CMC/EPS ensembles"
echo "------------------------------------------------"
echo "History: Oct 2013 - First implementation of this new script."
echo "         Oct 2016 - Modified for half degree ensembles."
echo "AUTHOR: Bo Cui  (wx20cb)"

###############################################################################
set -x
### To submit this job for T00Z, T06Z T12Z and T18Z, four cycles per day

### need pass the values of PDY, CYC, DATA, COMIN, COMOUT

export hourlist=$1
export workdir=$2

if [ ! -d $workdir ]; then
 mkdir -p $workdir
fi

cd $workdir

##############################################
# define exec variable, and entry grib utility
##############################################

export ENSPROB=$USHnaefs/naefs_bc_probability.sh
export ENSMDF=$USHnaefs/naefs_climate_anv.sh    
export ENSEFI=$USHnaefs/naefs_climate_efi.sh  
export ENSANOMALY=$USHnaefs/naefs_climate_anomaly.sh

########################################
#  define ensemble members and lead time
########################################

#hourlist="    003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 \
#          051 054 057 060 063 066 069 072 075 078 081 084 087 090 093 096 099 \
#          102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 \
#          153 156 159 162 165 168 171 174 177 180 183 186 189 192 198 204 \
#          210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
#          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

export memberlist_ncep="c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20 \
                            p21 p22 p23 p24 p25 p26 p27 p28 p29 p30 "
export memberlist_cmc="     p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"
export memberlist_fnmoc="   p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"

export prodlist="geavg gespr gemode ge10pt ge50pt ge90pt"

grid2="0 6 0 0 0 0 0 0 360 181 0 0 90000000 0 48 -90000000 359000000 1000000 1000000 0"

#################################################################################
### generate NAEFS joint ensemble probability forecast, ensemble average & spread
#################################################################################

if [ "$IFNAEFS" = "YES" ]; then

  for nfhrs in $hourlist; do

    export FHRLIST=$nfhrs

    o10pt_naefs_gb2=naefs_ge10pt.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
    o90pt_naefs_gb2=naefs_ge90pt.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
    o50pt_naefs_gb2=naefs_ge50pt.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
    omode_naefs_gb2=naefs_gemode.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
    oavg_naefs_gb2=naefs_geavg.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
    ospr_naefs_gb2=naefs_gespr.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
    omdf_naefs_gb2=naefs_geavg.t${cyc}z.pgrb2a.0p50_anvf$nfhrs
    oanf_naefs_gb2=naefs_geavg.t${cyc}z.pgrb2a.0p50_anf$nfhrs
    oefi_naefs_gb2=naefs_geefi.t${cyc}z.pgrb2a.0p50_bcf$nfhrs

    echo  " Start NAEFS Probability Forecast Calculation  "
    $ENSPROB     
    export MEMLIST=" avg "
    $ENSMDF     $PDY$cyc  $nfhrs
    $ENSANOMALY $PDY$cyc  $nfhrs
    $ENSEFI     $PDY$cyc  $nfhrs

    if [ "$SENDCOM" = "YES" ]; then

      for product in $prodlist; do
        oprod_gb2=${product}.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
        if [ -s $oprod_gb2 ]; then
          mv $oprod_gb2 $COMOUTNAEFS_p5/naefs_$oprod_gb2
        fi
      done 

      oprod_gb2=geavg.t${cyc}z.pgrb2a.0p50_anvf$nfhrs
      if [ -s $oprod_gb2 ]; then
        mv $oprod_gb2 $COMOUTNAEFSAN_p5/naefs_$oprod_gb2
      fi

      oprod_gb2=geavg.t${cyc}z.pgrb2a.0p50_anf$nfhrs
      if [ -s $oprod_gb2 ]; then
        mv $oprod_gb2 $COMOUTNAEFSAN_p5/naefs_$oprod_gb2
      fi

      oprod_gb2=geefi.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
      if [ -s $oprod_gb2 ]; then
        mv $oprod_gb2 $COMOUTNAEFSAN_p5/naefs_$oprod_gb2
      fi

      if [ "$IFENSBC1D" = "YES" ]; then
        for product in $prodlist; do
          infile=naefs_${product}.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
          outfile=naefs_${product}.t${cyc}z.pgrb2a_bcf$nfhrs
          $COPYGB2 -g "$grid2" -x $COMOUTNAEFS_p5/$infile $COMOUTNAEFS/$outfile
        done 
        infile=naefs_geavg.t${cyc}z.pgrb2a.0p50_anvf$nfhrs      
        outfile=naefs_geavg.t${cyc}z.pgrb2a_anvf$nfhrs
        $COPYGB2 -g "$grid2" -x $COMOUTNAEFSAN_p5/$infile $COMOUTNAEFSAN/$outfile
        infile=naefs_geavg.t${cyc}z.pgrb2a.0p50_anf$nfhrs      
        outfile=naefs_geavg.t${cyc}z.pgrb2a_anf$nfhrs
        $COPYGB2 -g "$grid2" -x $COMOUTNAEFSAN_p5/$infile $COMOUTNAEFSAN/$outfile
      fi

# Alert only the late files at 00z and 12z, since they include CMC data 

      if test "${cyc}" = "00" -o "${cyc}" = "12"; then
         if test "$SENDDBN" = 'YES'; then
            $DBNROOT/bin/dbn_alert MODEL NAEFS_BC_GB2 $job $COMOUTNAEFS_p5/$o10pt_naefs_gb2
            $DBNROOT/bin/dbn_alert MODEL NAEFS_BC_GB2 $job $COMOUTNAEFS_p5/$o50pt_naefs_gb2
            $DBNROOT/bin/dbn_alert MODEL NAEFS_BC_GB2 $job $COMOUTNAEFS_p5/$o90pt_naefs_gb2
            $DBNROOT/bin/dbn_alert MODEL NAEFS_BC_GB2 $job $COMOUTNAEFS_p5/$oavg_naefs_gb2
            $DBNROOT/bin/dbn_alert MODEL NAEFS_BC_GB2 $job $COMOUTNAEFS_p5/$omode_naefs_gb2
            $DBNROOT/bin/dbn_alert MODEL NAEFS_BC_GB2 $job $COMOUTNAEFS_p5/$ospr_naefs_gb2
            $DBNROOT/bin/dbn_alert MODEL NAEFS_AVGAN_GB2 $job $COMOUTNAEFSAN_p5/$omdf_naefs_gb2
            $DBNROOT/bin/dbn_alert MODEL NAEFS_AN_GB2 $job $COMOUTNAEFSAN_p5/$oanf_naefs_gb2
            $DBNROOT/bin/dbn_alert MODEL NAEFS_AN_GB2 $job $COMOUTNAEFSAN_p5/$oefi_naefs_gb2
         fi
      fi

    fi

  done
fi

##########################################################################
### calculate GEFS ensemble probability forecast, ensemble average & spread
##########################################################################

if [ "$IFGEFS" = "YES" ]; then

  for nfhrs in $hourlist; do

    export FHRLIST=$nfhrs

    o10pt_gefs_gb2=ge10pt.t${cyc}z.pgrb2a.0p50_bcf$nfhrs 
    o90pt_gefs_gb2=ge90pt.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
    o50pt_gefs_gb2=ge50pt.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
    oavg_gefs_gb2=geavg.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
    ospr_gefs_gb2=gespr.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
    omode_gefs_gb2=gemode.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
    omdf_gefs_gb2=geavg.t${cyc}z.pgrb2a.0p50_anvf$nfhrs
    oanf_gefs_gb2=geavg.t${cyc}z.pgrb2a.0p50_anf$nfhrs
    oefi_gefs_gb2=geefi.t${cyc}z.pgrb2a.0p50_bcf$nfhrs

    echo  " Start GEFS Probability Forecast Calculation  "
    $ENSPROB     
    export MEMLIST=" avg "
    $ENSMDF     $PDY$cyc $nfhrs
    $ENSANOMALY $PDY$cyc $nfhrs
    $ENSEFI     $PDY$cyc $nfhrs

    if [ "$SENDCOM" = "YES" ]; then
      for product in $prodlist; do
        oprod_gb2=${product}.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
        if [ -s $oprod_gb2 ]; then
          mv $oprod_gb2  $COMOUTGEFS_p5/
          $WGRIB2 -s $COMOUTGEFS_p5/$oprod_gb2 > $COMOUTGEFS_p5/$oprod_gb2.idx
        fi
      done 
      oprod_gb2=geavg.t${cyc}z.pgrb2a.0p50_anvf$nfhrs
      if [ -s $oprod_gb2 ]; then
        mv $oprod_gb2  $COMOUTGEFSAN_p5/
        # $WGRIB2 -s $COMOUTGEFS_p5/$oprod_gb2 > $COMOUTGEFSAN_p5/$oprod_gb2.idx
      fi
      oprod_gb2=geavg.t${cyc}z.pgrb2a.0p50_anf$nfhrs
      if [ -s $oprod_gb2 ]; then
        mv $oprod_gb2  $COMOUTGEFSAN_p5/
        # $WGRIB2 -s $COMOUTGEFS_p5/$oprod_gb2 > $COMOUTGEFSAN_p5/$oprod_gb2.idx
      fi
      oprod_gb2=geefi.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
      if [ -s $oprod_gb2 ]; then
        mv $oprod_gb2  $COMOUTGEFSAN_p5/
        # $WGRIB2 -s $COMOUTGEFS_p5/$oprod_gb2 > $COMOUTGEFSAN_p5/$oprod_gb2.idx
      fi
    fi

    if [ "$IFENSBC1D" = "YES" ]; then
      for product in $prodlist; do
        infile=${product}.t${cyc}z.pgrb2a.0p50_bcf$nfhrs
        outfile=${product}.t${cyc}z.pgrb2a_bcf$nfhrs
        $COPYGB2 -g "$grid2" -x $COMOUTGEFS_p5/$infile $COMOUTGEFS/$outfile
      done 
      infile=geavg.t${cyc}z.pgrb2a.0p50_anvf$nfhrs      
      outfile=geavg.t${cyc}z.pgrb2a_anvf$nfhrs
      $COPYGB2 -g "$grid2" -x $COMOUTGEFSAN_p5/$infile $COMOUTGEFSAN/$outfile
      infile=geavg.t${cyc}z.pgrb2a.0p50_anf$nfhrs      
      outfile=geavg.t${cyc}z.pgrb2a_anf$nfhrs
      $COPYGB2 -g "$grid2" -x $COMOUTGEFSAN_p5/$infile $COMOUTGEFSAN/$outfile
    fi

    if [ "$SENDDBN" = "YES" ]; then
              $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_BC_GB2 $job $COMOUTGEFS_p5/$o10pt_gefs_gb2
              $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_BC_GB2 $job $COMOUTGEFS_p5/$o50pt_gefs_gb2
              $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_BC_GB2 $job $COMOUTGEFS_p5/$o90pt_gefs_gb2
              $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_BC_GB2 $job $COMOUTGEFS_p5/$oavg_gefs_gb2
              $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_BC_GB2 $job $COMOUTGEFS_p5/$omode_gefs_gb2
              $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_BC_GB2 $job $COMOUTGEFS_p5/$ospr_gefs_gb2
              $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_AN_GB2 $job $COMOUTGEFSAN_p5/$omdf_gefs_gb2 
              $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_AN_GB2 $job $COMOUTGEFSAN_p5/$oanf_gefs_gb2
              $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_AN_GB2 $job $COMOUTGEFSAN_p5/$oefi_gefs_gb2
              $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_BC_GB2_WIDX $job $COMOUTGEFS_p5/$o10pt_gefs_gb2.idx
              $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_BC_GB2_WIDX $job $COMOUTGEFS_p5/$o50pt_gefs_gb2.idx
              $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_BC_GB2_WIDX $job $COMOUTGEFS_p5/$o90pt_gefs_gb2.idx
              $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_BC_GB2_WIDX $job $COMOUTGEFS_p5/$oavg_gefs_gb2.idx
              $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_BC_GB2_WIDX $job $COMOUTGEFS_p5/$omode_gefs_gb2.idx
              $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_BC_GB2_WIDX $job $COMOUTGEFS_p5/$ospr_gefs_gb2.idx
              # $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_AN_GB2_WIDX $job $COMOUTGEFSAN_p5/$omdf_gefs_gb2.idx 
              # $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_AN_GB2_WIDX $job $COMOUTGEFSAN_p5/$oanf_gefs_gb2.idx
              # $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_AN_GB2_WIDX $job $COMOUTGEFSAN_p5/$oefi_gefs_gb2.idx
    fi

  done
fi

msg="NAEFS PRODUCTS PRODUCTION HAS COMPLETED NORMALLY!"
postmsg "$jlogfile" "$msg"

exit 0
