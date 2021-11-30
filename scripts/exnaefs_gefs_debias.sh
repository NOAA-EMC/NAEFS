#################################### FORECAST DEBIAS #########################################
# Bias Correct NCEP Global Ensemble Forecast & GFS Forecast
# History:
#         March 2006 - First implementation of this new script
#         March 2007 - Modified for GEFS upgrade (20 members)
#         May   2007 - Add GFS bias correction
#         Aug   2007 - Add hybrid method to combine bias-corrected GFS and bias-corrected GEFS
#         June  2015 - Add new variable (TCDC) 
#         June  2016 - Modified for half degree ensembl forecasts
# AUTHOR: Bo Cui  (wx20cb)
###############################################################################################

### To submit this job for T00Z, T06Z T12Z and T18Z, four cycles per day
### need pass the values of PDY, CYC, DATA, COMIN, COM, COMOUTBC, COMOUTAN and COMOUTWT

################################################################
# define exec variable, and entry grib utility 
################################################################

set -x

export memberlist=$1
export workdir=$2
export event_flag=NO
beg=`date +%s`

if [ ! -f $workdir ]; then
  mkdir -p $workdir
fi

cd $workdir

export ENSANOMALY=$USHgefs/gefs_climate_anomaly.sh
export ENSWEIGHTS=$USHgefs/gefs_weights.sh

export pgm=gefs_debias
. prep_step

########################################################
### define the days for searching bias estimation backup
########################################################

ymdh=${PDY}${cyc}
export PDYm8=`$NDATE -192 $ymdh | cut -c1-8`
export PDYm9=`$NDATE -216 $ymdh | cut -c1-8`
export PDYm10=`$NDATE -240 $ymdh | cut -c1-8`
export PDYm11=`$NDATE -264 $ymdh | cut -c1-8`
export PDYm12=`$NDATE -288 $ymdh | cut -c1-8`
export PDYm13=`$NDATE -312 $ymdh | cut -c1-8`
export PDYm14=`$NDATE -336 $ymdh | cut -c1-8`
export PDYm15=`$NDATE -360 $ymdh | cut -c1-8`
export PDYm16=`$NDATE -384 $ymdh | cut -c1-8`

##########################################################################
# bias correct NCEP global ensemble for each forecast time and each member
##########################################################################

#export memberlist="c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 \
#                   p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"

grid2="0 6 0 0 0 0 0 0 360 181 0 0 90000000 0 48 -90000000 359000000 1000000 1000000 0"

hourlist="000 003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 \
          051 054 057 060 063 066 069 072 075 078 081 084 087 090 093 096 099 \
          102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 \
          153 156 159 162 165 168 171 174 177 180 183 186 189 192 198 204 \
          210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

event_hourlist="000 003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 \
                051 054 057 060 063 066 069 072 075 078 081 084 087 090 093 096 099 \
                102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 \
                153 156 159 162 165 168 171 174 177 180 183 186 189 192 198 204 210 \
                216 222 228 234 240"

for nens in $memberlist; do

  if [ "$nens" = "gfs" ]; then
    hourlist="000 003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 \
              051 054 057 060 063 066 069 072 075 078 081 084 087 090 093 096 099 \
              102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 \
              153 156 159 162 165 168 171 174 177 180"
  fi

  for nfhrs in $hourlist; do

###
#  set the index ( exist of bias estimation ) as default, 0
###

    cstart_ens=0
    cstart_gfs=0
    if_gfs=0

###
#  GEFS bias estimation entry, if_gfs: 1 = for GFS high resolution forecast
###

    ibias_ens=geavg.t${cyc}z.pgrb2a.0p50_mecomf${nfhrs}

    if [ "$nens" = "gfs" ]; then
      ibias_ens=gegfs.t${cyc}z.pgrb2a.0p50_mef${nfhrs}
      if_gfs=1
    fi

    if [ -s $COMINbias/gefs.$PDY/${cyc}/pgrb2ap5/$ibias_ens ]; then
      cp $COMINbias/gefs.$PDY/${cyc}/pgrb2ap5/$ibias_ens $ibias_ens
    elif [ -s $COMINbias/gefs.$PDYm1/${cyc}/pgrb2ap5/$ibias_ens ]; then
      cp $COMINbias/gefs.$PDYm1/${cyc}/pgrb2ap5/$ibias_ens $ibias_ens
    elif [ -s $COMINbias/gefs.$PDYm2/${cyc}/pgrb2ap5/$ibias_ens ]; then
      cp $COMINbias/gefs.$PDYm2/${cyc}/pgrb2ap5/$ibias_ens $ibias_ens
    elif [ -s $COMINbias/gefs.$PDYm3/${cyc}/pgrb2ap5/$ibias_ens ]; then
      cp $COMINbias/gefs.$PDYm3/${cyc}/pgrb2ap5/$ibias_ens $ibias_ens
    elif [ -s $COMINbias/gefs.$PDYm4/${cyc}/pgrb2ap5/$ibias_ens ]; then
      cp $COMINbias/gefs.$PDYm4/${cyc}/pgrb2ap5/$ibias_ens $ibias_ens
    elif [ -s $COMINbias/gefs.$PDYm5/${cyc}/pgrb2ap5/$ibias_ens ]; then
      cp $COMINbias/gefs.$PDYm5/${cyc}/pgrb2ap5/$ibias_ens $ibias_ens
    elif [ -s $COMINbias/gefs.$PDYm6/${cyc}/pgrb2ap5/$ibias_ens ]; then
      cp $COMINbias/gefs.$PDYm6/${cyc}/pgrb2ap5/$ibias_ens $ibias_ens
    elif [ -s $COMINbias/gefs.$PDYm7/${cyc}/pgrb2ap5/$ibias_ens ]; then
      cp $COMINbias/gefs.$PDYm7/${cyc}/pgrb2ap5/$ibias_ens $ibias_ens
    elif [ -s $COMINbias/gefs.$PDYm8/${cyc}/pgrb2ap5/$ibias_ens ]; then
      cp $COMINbias/gefs.$PDYm8/${cyc}/pgrb2ap5/$ibias_ens $ibias_ens
    elif [ -s $COMINbias/gefs.$PDYm9/${cyc}/pgrb2ap5/$ibias_ens ]; then
      cp $COMINbias/gefs.$PDYm9/${cyc}/pgrb2ap5/$ibias_ens $ibias_ens
    elif [ -s $COMINbias/gefs.$PDYm10/${cyc}/pgrb2ap5/$ibias_ens ]; then
      cp $COMINbias/gefs.$PDYm10/${cyc}/pgrb2ap5/$ibias_ens $ibias_ens
    elif [ -s $COMINbias/gefs.$PDYm11/${cyc}/pgrb2ap5/$ibias_ens ]; then
      cp $COMINbias/gefs.$PDYm11/${cyc}/pgrb2ap5/$ibias_ens $ibias_ens
    elif [ -s $COMINbias/gefs.$PDYm12/${cyc}/pgrb2ap5/$ibias_ens ]; then
      cp $COMINbias/gefs.$PDYm12/${cyc}/pgrb2ap5/$ibias_ens $ibias_ens
    elif [ -s $COMINbias/gefs.$PDYm13/${cyc}/pgrb2ap5/$ibias_ens ]; then
      cp $COMINbias/gefs.$PDYm13/${cyc}/pgrb2ap5/$ibias_ens $ibias_ens
    elif [ -s $COMINbias/gefs.$PDYm14/${cyc}/pgrb2ap5/$ibias_ens ]; then
      cp $COMINbias/gefs.$PDYm14/${cyc}/pgrb2ap5/$ibias_ens $ibias_ens
    elif [ -s $COMINbias/gefs.$PDYm15/${cyc}/pgrb2ap5/$ibias_ens ]; then
      cp $COMINbias/gefs.$PDYm15/${cyc}/pgrb2ap5/$ibias_ens $ibias_ens
    elif [ -s $COMINbias/gefs.$PDYm16/${cyc}/pgrb2ap5/$ibias_ens ]; then
      cp $COMINbias/gefs.$PDYm16/${cyc}/pgrb2ap5/$ibias_ens $ibias_ens
    else
      echo " There is no Bias Estimation at " ${nfhrs} 
      cstart_ens=1
    fi

###
#  GFS bias estimation entry
###

    ibias_gfs=gegfs.t${cyc}z.pgrb2a.0p50_mef${nfhrs}

    if [ -s $COMINbias/gefs.$PDY/${cyc}/pgrb2ap5/$ibias_gfs ]; then
      cp $COMINbias/gefs.$PDY/${cyc}/pgrb2ap5/$ibias_gfs $ibias_gfs
    elif [ -s $COMINbias/gefs.$PDYm1/${cyc}/pgrb2ap5/$ibias_gfs ]; then
      cp $COMINbias/gefs.$PDYm1/${cyc}/pgrb2ap5/$ibias_gfs $ibias_gfs
    elif [ -s $COMINbias/gefs.$PDYm2/${cyc}/pgrb2ap5/$ibias_gfs ]; then
      cp $COMINbias/gefs.$PDYm2/${cyc}/pgrb2ap5/$ibias_gfs $ibias_gfs
    elif [ -s $COMINbias/gefs.$PDYm3/${cyc}/pgrb2ap5/$ibias_gfs ]; then
      cp $COMINbias/gefs.$PDYm3/${cyc}/pgrb2ap5/$ibias_gfs $ibias_gfs
    elif [ -s $COMINbias/gefs.$PDYm4/${cyc}/pgrb2ap5/$ibias_gfs ]; then
      cp $COMINbias/gefs.$PDYm4/${cyc}/pgrb2ap5/$ibias_gfs $ibias_gfs
    elif [ -s $COMINbias/gefs.$PDYm5/${cyc}/pgrb2ap5/$ibias_gfs ]; then
      cp $COMINbias/gefs.$PDYm5/${cyc}/pgrb2ap5/$ibias_gfs $ibias_gfs
    elif [ -s $COMINbias/gefs.$PDYm6/${cyc}/pgrb2ap5/$ibias_gfs ]; then
      cp $COMINbias/gefs.$PDYm6/${cyc}/pgrb2ap5/$ibias_gfs $ibias_gfs
    elif [ -s $COMINbias/gefs.$PDYm7/${cyc}/pgrb2ap5/$ibias_gfs ]; then
      cp $COMINbias/gefs.$PDYm7/${cyc}/pgrb2ap5/$ibias_gfs $ibias_gfs
    elif [ -s $COMINbias/gefs.$PDYm8/${cyc}/pgrb2ap5/$ibias_gfs ]; then
      cp $COMINbias/gefs.$PDYm8/${cyc}/pgrb2ap5/$ibias_gfs $ibias_gfs
    elif [ -s $COMINbias/gefs.$PDYm9/${cyc}/pgrb2ap5/$ibias_gfs ]; then
      cp $COMINbias/gefs.$PDYm9/${cyc}/pgrb2ap5/$ibias_gfs $ibias_gfs
    elif [ -s $COMINbias/gefs.$PDYm10/${cyc}/pgrb2ap5/$ibias_gfs ]; then
      cp $COMINbias/gefs.$PDYm10/${cyc}/pgrb2ap5/$ibias_gfs $ibias_gfs
    elif [ -s $COMINbias/gefs.$PDYm11/${cyc}/pgrb2ap5/$ibias_gfs ]; then
      cp $COMINbias/gefs.$PDYm11/${cyc}/pgrb2ap5/$ibias_gfs $ibias_gfs
    elif [ -s $COMINbias/gefs.$PDYm12/${cyc}/pgrb2ap5/$ibias_gfs ]; then
      cp $COMINbias/gefs.$PDYm12/${cyc}/pgrb2ap5/$ibias_gfs $ibias_gfs
    elif [ -s $COMINbias/gefs.$PDYm13/${cyc}/pgrb2ap5/$ibias_gfs ]; then
      cp $COMINbias/gefs.$PDYm13/${cyc}/pgrb2ap5/$ibias_gfs $ibias_gfs
    elif [ -s $COMINbias/gefs.$PDYm14/${cyc}/pgrb2ap5/$ibias_gfs ]; then
      cp $COMINbias/gefs.$PDYm14/${cyc}/pgrb2ap5/$ibias_gfs $ibias_gfs
    elif [ -s $COMINbias/gefs.$PDYm15/${cyc}/pgrb2ap5/$ibias_gfs ]; then
      cp $COMINbias/gefs.$PDYm15/${cyc}/pgrb2ap5/$ibias_gfs $ibias_gfs
    elif [ -s $COMINbias/gefs.$PDYm16/${cyc}/pgrb2ap5/$ibias_gfs ]; then
      cp $COMINbias/gefs.$PDYm16/${cyc}/pgrb2ap5/$ibias_gfs $ibias_gfs
    else
      echo " There is no GFS Bias Estimation at " ${nfhrs} 
      cstart_gfs=1
    fi

    echo "&message"  >input.$nfhrs.$nens
    echo " icstart_ens=${cstart_ens}," >> input.$nfhrs.$nens
    echo " icstart_gfs=${cstart_gfs}," >> input.$nfhrs.$nens
    echo " if_gfs=${if_gfs}," >> input.$nfhrs.$nens
    echo " nfhr=${nfhrs}," >> input.$nfhrs.$nens
    echo "/" >>input.$nfhrs.$nens

###
#  GEFS bias corrected ensemble forecasting output
###

    ofile=ge${nens}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}

###
#  check GEFS, GFS and GEFS control forecast file
###
   
    ifile_ens=$COMINgefs/ge${nens}.t${cyc}z.pgrb2a.0p50.f${nfhrs} 
    ifile_ctl=$COMINgefs/gec00.t${cyc}z.pgrb2a.0p50.f${nfhrs} 
    ifile_gfs=$COMINgefs/gegfs.t${cyc}z.pgrb2a.0p50.f${nfhrs} 

    icnt=0
    while [ $icnt -le 30 ]; do

      if [ -s $ifile_ens -a -s $ifile_ctl ]; then

        ln -sf $ibias_ens fort.11
        ln -sf $ifile_ens fort.12
        ln -sf $ibias_gfs fort.13
        ln -sf $ifile_gfs fort.14
        ln -sf $ifile_ctl fort.15
        ln -sf $ofile     fort.51

        startmsg
        $EXECgefs/$pgm   <input.$nfhrs.$nens     > $pgmout.$nfhrs.$nens 2> errfile
        export err=$?;err_chk
 	rm fort.*

        export MEMLIST=$nens
        $ENSANOMALY $PDY$cyc $nfhrs
        if [ "$nens" != "gfs" ]; then
          $ENSWEIGHTS $PDY$cyc $nfhrs
        fi

        icnt=31

#### sendcom  bias corrected forecast
#### and convert to grib2

        if [ "$SENDCOM" = "YES" ]; then

          outfile=ge${nens}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}
          if [ -s $outfile ]; then
            mv $outfile $COMOUTBC_p5/
            $WGRIB2 -s $COMOUTBC_p5/$outfile > $COMOUTBC_p5/$outfile.idx

           if [ ${nfhrs} = 240 ]; then
             ic=0
             for hr in ${event_hourlist};do
               if [ -s $COMOUTBC_p5/ge${nens}.t${cyc}z.pgrb2a.0p50_bcf${hr} ]; then
                 let ic=ic+1
               else
                 echo " MISSING FILE "ge${nens}.t${cyc}z.pgrb2a.0p50_bcf${hr}" !"
                 echo " WILL MAKE UP at all other hour finishes!"
               fi
             done
             if [ $ic -eq  73 ]; then
               ecflow_client --event pgrb2a.0p50_bcf240_ge${nens}
               export event_flag=YES
             fi
           fi

            if [ "$SENDDBN" = "YES" ]; then
               MEMBER=`echo $nens | tr '[a-z]' '[A-Z]'`
               $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PGB2A_BC $job $COMOUTBC_p5/$outfile
               $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PGB2A_BC_WIDX $job $COMOUTBC_p5/$outfile.idx
            fi 
	  fi

          outfile=ge${nens}.t${cyc}z.pgrb2a.0p50_anf$nfhrs
          if [ -s $outfile ]; then
            mv $outfile $COMOUTAN_p5/
            # $WGRIB2 -s $COMOUTAN_p5/$outfile > $COMOUTAN_p5/$outfile.idx
            if [ "$SENDDBN" = "YES" -a $nfhrs != 000 ]; then
               MEMBER=`echo $nens | tr '[a-z]' '[A-Z]'`
               $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PGBR2A_AN $job $COMOUTAN_p5/$outfile
               # $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PGBR2A_AN $job $COMOUTAN_p5/$outfile.idx
            fi 
          fi

          outfile=ge${nens}.t${cyc}z.pgrb2a.0p50_wtf$nfhrs
          if [ -s $outfile ]; then
            mv $outfile $COMOUTWT_p5/
          fi

          if [ "$IFENSBC1D" = "YES" ]; then
            infile=ge${nens}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}
            outfile=ge${nens}.t${cyc}z.pgrb2a_bcf${nfhrs}
            if [ -s $COMOUTBC_p5/$infile ]; then
              $COPYGB2 -g "$grid2" -x $COMOUTBC_p5/$infile $COMOUTBC/$outfile
            fi
            infile=ge${nens}.t${cyc}z.pgrb2a.0p50_anf${nfhrs}
            outfile=ge${nens}.t${cyc}z.pgrb2a_anf${nfhrs}
            if [ -s $COMOUTAN_p5/$infile ]; then
              $COPYGB2 -g "$grid2" -x $COMOUTAN_p5/$infile $COMOUTAN/$outfile
            fi
#           infile=ge${nens}.t${cyc}z.pgrb2a.0p50_wtf${nfhrs}
#           outfile=ge${nens}.t${cyc}z.pgrb2a_wtf${nfhrs}
#           if [ -s $COMOUTWT_p5/$infile ]; then
#             $COPYGB2 -g "$grid2" -x $COMOUTWT_p5/$infile $COMOUTWT/$outfile
#           fi
          fi

        fi

      else

        sleep 10
        icnt=`expr $icnt + 1`

      fi
    done

  done
done

###
#  final check up and make up
###

for nens in $memberlist; do

  hourlist="000 003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 \
            051 054 057 060 063 066 069 072 075 078 081 084 087 090 093 096 099 \
            102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 \
            153 156 159 162 165 168 171 174 177 180 183 186 189 192 198 204 \
            210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
            306 312 318 324 330 336 342 348 354 360 366 372 378 384"

  event_hourlist="000 003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 \
                  051 054 057 060 063 066 069 072 075 078 081 084 087 090 093 096 099 \
                  102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 \
                  153 156 159 162 165 168 171 174 177 180 183 186 189 192 198 204 210 \
                  216 222 228 234 240"

  if [ "$nens" = "gfs" ]; then
    hourlist="000 003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 \
              051 054 057 060 063 066 069 072 075 078 081 084 087 090 093 096 099 \
              102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 \
              153 156 159 162 165 168 171 174 177 180"
  fi

  for nfhrs in $hourlist; do

    if [ ! -s $COMOUTBC_p5/ge${nens}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs} ]; then  

      rm fort.* input.$nfhrs.$nens
      echo "&message"  >input.$nfhrs.$nens
      echo " icstart_ens=${cstart_ens}," >> input.$nfhrs.$nens
      echo " icstart_gfs=${cstart_gfs}," >> input.$nfhrs.$nens
      echo " if_gfs=${if_gfs}," >> input.$nfhrs.$nens
      echo " nfhr=${nfhrs}," >> input.$nfhrs.$nens
      echo "/" >>input.$nfhrs.$nens

      ibias_ens=geavg.t${cyc}z.pgrb2a.0p50_mecomf${nfhrs}
      if [ "$nens" = "gfs" ]; then
        ibias_ens=gegfs.t${cyc}z.pgrb2a.0p50_mef${nfhrs}
      fi
      ibias_gfs=gegfs.t${cyc}z.pgrb2a.0p50_mef${nfhrs}
      ifile_ens=$COMINgefs/ge${nens}.t${cyc}z.pgrb2a.0p50.f${nfhrs} 
      ifile_ctl=$COMINgefs/gec00.t${cyc}z.pgrb2a.0p50.f${nfhrs} 
      ifile_gfs=$COMINgefs/gegfs.t${cyc}z.pgrb2a.0p50.f${nfhrs} 
      ofile=ge${nens}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}

      ln -sf $ibias_ens fort.11
      ln -sf $ifile_ens fort.12
      ln -sf $ibias_gfs fort.13
      ln -sf $ifile_gfs fort.14
      ln -sf $ifile_ctl fort.15
      ln -sf $ofile     fort.51

      startmsg
      $EXECgefs/$pgm   <input.$nfhrs.$nens    > $pgmout.$nfhrs.$nens 2> errfile
      export err=$?;err_chk
      if [ "$SENDCOM" = "YES" ]; then
        if [ -s $ofile ]; then  
          cp $ofile $COMOUTBC_p5/
          $WGRIB2 -s $COMOUTBC_p5/$ofile > $COMOUTBC_p5/$ofile.idx
          if [ "$IFENSBC1D" = "YES" ]; then
            infile=ge${nens}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}
            outfile=ge${nens}.t${cyc}z.pgrb2a_bcf${nfhrs}
            $COPYGB2 -g "$grid2" -x $COMOUTBC_p5/$infile $COMOUTBC/$outfile
          fi
#         if [ ${nfhrs} = 240 ]; then
#           ic=0
#           for hr in ${event_hourlist};
#           do
#             if [ -s $COMOUTBC_p5/ge${nens}.t${cyc}z.pgrb2a.0p50_bcf${hr} ]; then
#               let ic=ic+1
#             else
#               echo " MISSING FILE "ge${nens}.t${cyc}z.pgrb2a..0p50.f${hr}" !"
#               echo " WILL MAKE UP at all other hour finishes!"
#             fi
#           done
#           if [ $ic -eq  72 -a ${event_flag} = NO ]; then
#             ecflow_client --event pgrba_bcf240_ge${nens}
#             export event_flag=YES
#           fi
#         fi
          if [ "$SENDDBN" = "YES" -a $nfhrs != 000 ]; then
            MEMBER=`echo $nens | tr '[a-z]' '[A-Z]'`
            $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PGB2A_BC $job $COMOUTBC_p5/$ofile
            $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PGB2A_BC_WIDX $job $COMOUTBC_p5/$ofile.idx 
          fi
        fi
      fi
    fi
    if [ ! -s $COMOUTAN_p5/ge${nens}.t${cyc}z.pgrb2a.0p50_anf$nfhrs ]; then
      rm fort.*
      echo " No Anomaly " $COMOUTAN_p5/ge${nens}.t${cyc}z.pgrb2a.0p50_anf$nfhrs
      export MEMLIST=$nens
      $ENSANOMALY $PDY$cyc $nfhrs
      if [ "$SENDCOM" = "YES" ]; then
        outfile=ge${nens}.t${cyc}z.pgrb2a.0p50_anf$nfhrs
        if [ -s $outfile ]; then
          mv $outfile $COMOUTAN_p5/
          # $WGRIB2 -s $COMOUTAN_p5/$outfile > $COMOUTAN_p5/$outfile.idx
          if [ "$SENDDBN" = "YES" -a $nfhrs != 000 ]; then
             MEMBER=`echo $nens | tr '[a-z]' '[A-Z]'`
             $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PGBR2A_AN $job $COMOUTAN_p5/$outfile
             # $DBNROOT/bin/dbn_alert MODEL NAEFS_GEFS_PGBR2A_AN $job $COMOUTAN_p5/$outfile.idx
          fi 
          if [ "$IFENSBC1D" = "YES" ]; then
            infile=ge${nens}.t${cyc}z.pgrb2a.0p50_anf${nfhrs}
            outfile=ge${nens}.t${cyc}z.pgrb2a_anf${nfhrs}
            $COPYGB2 -g "$grid2" -x $COMOUTAN_p5/$infile $COMOUTAN/$outfile
          fi
        fi
      fi
    fi
    if [ ! -s $COMOUTWT_p5/ge${nens}.t${cyc}z.pgrb2a_wtf$nfhrs ]; then
      rm fort.*
      export MEMLIST=$nens
      if [ "$nens" != "gfs" ]; then
        $ENSWEIGHTS $PDY$cyc $nfhrs
      fi
      if [ "$SENDCOM" = "YES" ]; then
        outfile=ge${nens}.t${cyc}z.pgrb2a.0p50_wtf$nfhrs
        if [ -s $outfile ]; then
          mv $outfile $COMOUTWT_p5/
#         if [ "$IFENSBC1D" = "YES" ]; then
#           infile=ge${nens}.t${cyc}z.pgrb2a.0p50_wtf${nfhrs}
#           outfile=ge${nens}.t${cyc}z.pgrb2a_wtf${nfhrs}
#           $COPYGB2 -g "$grid2" -x $COMOUTWT_p5/$infile $COMOUTWT/$outfile
#         fi
        fi
      fi
    fi
  done
###
done

msg="HAS COMPLETED NORMALLY!"
postmsg "$jlogfile" "$msg"

exit 0
