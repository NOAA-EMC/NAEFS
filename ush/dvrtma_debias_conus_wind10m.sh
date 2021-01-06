######################################################################################
# Script:   dvrtma_debias_conus_wind10m.sh
# Abstract: Downscale Ensemble Products on Conus Region for Variables 10m Wdir & Wspd 
# Author:   Bo Cui
# History:  October 2013 - First implementation of this new script
#           June    2015 - NAEFS version 5 modified for 2.5km products
#######################################################################################

echo "----------------------------------------------------------------------"
echo "dvrtma_debias_conus_wind10m.sh: downscale wind speed & wind direction"
echo "----------------------------------------------------------------------"

set -x

##############################################
# define exec variable, and entry grib utility
##############################################

CMCEADJUST=$USHrtma/cmce_adjust_wind10m_conus.sh

pgm=dvrtma_debias_conus_wind10m
pgmout=output_ds_wind10m 

###########################################
#  define ensemble members for NCEP and CMC
###########################################

if [ "$IFNAEFS" = "YES" ]; then
  if [ $cyc -eq 00 -o $cyc -eq 12 ]; then
    memberlist="$memberlist_cmc $memberlist_ncep "
  fi   
  if [ "$cyc" = "06" -o "$cyc" = "18" ]; then
    memberlist="$memberlist_ncep "
  fi
  centerlist="naefs"
  out=naefs
fi

if [ "$IFGEFS" = "YES" ]; then
  memberlist="$memberlist_ncep"
  centerlist="gefs"
  out=gefs
fi

if [ "$IFCMCE" = "YES" ]; then
  memberlist="$memberlist_cmc"
  centerlist="cmce"
  out=cmce
fi

####################################
# calculate the ensemble member size
####################################

tmems=0
for imem in $memberlist; do
  (( tmems = tmems + 1 ))
done

########################################################
# set PDS message for grids of 2.539km for Conus region
########################################################

#grid="30 6 0 0 0 0 0 0 1073 689 20191999 238445999 8 25000000 265000000 \
#      5079406 5079406 0 64 25000000 25000000 -90000000 0 "

#grid="30 6 0 0 0 0 0 0 2145 1377 20191999 238445999 8 25000000 265000000 \
#      2539703 2539703 0 64 25000000 25000000 -90000000 0"

grid="30 6 0 0 0 0 0 0 2145 1597 20191999 238445999 8 25000000 265000000 \
      2539703 2539703 0 64 25000000 25000000 -90000000 0"

###################################################################################
# Adjust CMC ensemble forecast, all members are shift to NCEP analysis
# Input CMC Ensemble forecast, all members are saved in one file for one lead time 
###################################################################################

if [ $cyc -eq 00 -o $cyc -eq 12 ]; then

  if [ "$IFNAEFS" = "YES" -o  "$IFCMCE" = "YES" ]; then
 
    $CMCEADJUST

    cd $DATA/tmpdir_03 

    for nfhrs in $hourlist; do
      ofile_temp=cmce.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_temp
      for mem in $memberlist_cmc; do
       file_temp=cmc_ge$mem.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_temp
       cat $file_temp >>$ofile_temp
     done 
    done

    if [ -s poescript_cmce ]; then
      rm poescript_cmce
    fi

    for nfhrs in $hourlist; do
      file_temp=cmce.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_temp
      outfile=cmce.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ -s $file_temp ]; then
        echo "$COPYGB2 -g \"$grid\" -i1,1 -x $file_temp $outfile" >>poescript_cmce
      else
        echo "echo "no file of" $file_temp "                     >>poescript_cmce
      fi
    done

    chmod +x poescript_cmce
    startmsg
    $APRUN poescript_cmce
    export err=$?; err_chk
    wait

  fi
fi

wait

###################################################################################
# input NCEP Ensemble forecast, all members are saved in one file for one lead time 
###################################################################################

if [ "$IFNAEFS" = "YES" -o  "$IFGEFS" = "YES" ]; then

# for nfhrs in $hourlist; do
#   file_temp=gefs.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_temp
#   outfile=gefs.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
#   if [ -s $file_temp ]; then
#     rm $file_temp
#   fi
#   >$file_temp
#   for mem in ${memberlist_ncep}; do
#     infile=$COM_NCEP/gefs.$PDY/${cyc}/pgrb2a_bc/ge${mem}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}
#     if [ -s $infile ]; then
#       $WGRIB2 -match ":UGRD:"  -match "10 m "   $infile  -append -grib  $file_temp
#       $WGRIB2 -match ":VGRD:"  -match "10 m "   $infile  -append -grib  $file_temp
#     else
#       echo "File $infile is missing"
#     fi
#   done    
# done     

  for nfhrs in $hourlist; do
    if [ -s poe.$nfhrs ]; then rm poe.$nfhrs; fi
    file_temp=gefs.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_temp
    echo ">$file_temp" >> poe.$nfhrs
    for mem in ${memberlist_ncep}; do
      infile=$COM_NCEP/gefs.$PDY/${cyc}/pgrb2ap5_bc/ge${mem}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}
      if [ -s $infile ]; then
        echo "$WGRIB2 -match \":UGRD:\" -match \"10 m \" $infile -append -grib $file_temp">> poe.$nfhrs
        echo "$WGRIB2 -match \":VGRD:\" -match \"10 m \" $infile -append -grib $file_temp">> poe.$nfhrs
      else
        echo "echo \"File $infile is missing\"" >> poe.$nfhrs
      fi
    done
  done

  if [ -s poescript_gefs_wgrib ]; then rm poescript_gefs_wgrib; fi
  for nfhrs in $hourlist; do
    chmod +x poe.$nfhrs                 
    echo "poe.$nfhrs" >> poescript_gefs_wgrib
  done

  chmod +x poescript_gefs_wgrib
  startmsg
  $APRUN poescript_gefs_wgrib
  export err=$?; err_chk
  wait

  if [ -s poescript_gefs ]; then
    rm poescript_gefs
  fi

  for nfhrs in $hourlist; do
    file_temp=gefs.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_temp
    outfile=gefs.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
    if [ -s $file_temp ]; then
      echo "$COPYGB2 -g \"$grid\" -i1,1 -x $file_temp $outfile" >>poescript_gefs
    else
      echo "echo "no file of" $file_temp "                     >>poescript_gefs
    fi
  done
  chmod +x poescript_gefs
  startmsg
  $APRUN poescript_gefs
  export err=$?; err_chk
  wait

fi

wait

#########################################
# Combine GEFS and CMCE ensemble together
#########################################

if [ "$IFNAEFS" = "YES" ]; then
  if [ $cyc -eq 00 -o $cyc -eq 12 ]; then
    for nfhrs in $hourlist; do
      infile1=gefs.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      infile2=cmce.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      outfile=$out.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ -s $outfile ]; then
        rm $outfile
      fi
      >$outfile
      cat $infile1 $infile2 >$outfile     
    done
  fi
  if [ $cyc -eq 06 -o $cyc -eq 18 ]; then
    for nfhrs in $hourlist; do
      infile1=gefs.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      outfile=$out.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      mv $infile1 $outfile     
    done
  fi
fi

####################
# set up input files
####################
icount=0

for nfhrs in $hourlist; do

  if [ -s namin.wind.prob.$nfhrs ]; then
    rm namin.wind.prob.$nfhrs
  fi

  echo " &namens" >>namin.wind.prob.$nfhrs

  infile=$out.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5

  echo " tfiles=$tmems," >>namin.wind.prob.$nfhrs
  echo " cfipg1='${infile}'," >>namin.wind.prob.$nfhrs

###########################
# set up downscaling vector
##########################

  cyc_verf=`$NDATE +$nfhrs $PDY$cyc | cut -c9-10`

  ifile=dvrtma.t${cyc_verf}z.conus_ext_2p5.grib2 

  cstart=0

  if [ -s $COM_DV/gefs.$PDY/${cyc_verf}/ndgd_gb2/$ifile ]; then
    cp $COM_DV/gefs.$PDY/${cyc_verf}/ndgd_gb2/$ifile $ifile.f$nfhrs
  elif [ -s $COM_DV/gefs.$PDYm1/${cyc_verf}/ndgd_gb2/$ifile ]; then
    cp $COM_DV/gefs.$PDYm1/${cyc_verf}/ndgd_gb2/$ifile $ifile.f$nfhrs
  elif [ -s $COM_DV/gefs.$PDYm2/${cyc_verf}/ndgd_gb2/$ifile ]; then
    cp $COM_DV/gefs.$PDYm2/${cyc_verf}/ndgd_gb2/$ifile $ifile.f$nfhrs
  elif [ -s $COM_DV/gefs.$PDYm3/${cyc_verf}/ndgd_gb2/$ifile ]; then
    cp $COM_DV/gefs.$PDYm3/${cyc_verf}/ndgd_gb2/$ifile $ifile.f$nfhrs
  elif [ -s $COM_DV/gefs.$PDYm4/${cyc_verf}/ndgd_gb2/$ifile ]; then
    cp $COM_DV/gefs.$PDYm4/${cyc_verf}/ndgd_gb2/$ifile $ifile.f$nfhrs
  elif [ -s $COM_DV/gefs.$PDYm5/${cyc_verf}/ndgd_gb2/$ifile ]; then
    cp $COM_DV/gefs.$PDYm5/${cyc_verf}/ndgd_gb2/$ifile $ifile.f$nfhrs
  elif [ -s $COM_DV/gefs.$PDYm6/${cyc_verf}/ndgd_gb2/$ifile ]; then
    cp $COM_DV/gefs.$PDYm6/${cyc_verf}/ndgd_gb2/$ifile $ifile.f$nfhrs
  elif [ -s $COM_DV/gefs.$PDYm7/${cyc_verf}/ndgd_gb2/$ifile ]; then
    cp $COM_DV/gefs.$PDYm7/${cyc_verf}/ndgd_gb2/$ifile $ifile.f$nfhrs
  else
    echo " There is no Bias Estimation at " ${cyc_verf}Z
    cstart=1
  fi

  echo " icstart=${cstart}," >> namin.wind.prob.$nfhrs 
  echo " cfipg2='${ifile}.f${nfhrs}'," >>namin.wind.prob.$nfhrs

#####################
# set up output files
#####################

  ofile=t${cyc}z.ndgd_conusf${nfhrs}_part2
 
  if [ -s $ofile ]; then
    rm *_$ofile
  fi

  if [ "$IFNAEFS" = "YES" ]; then
    echo " cfopg1='naefs_ge10pt.${ofile}'," >>namin.wind.prob.$nfhrs
    echo " cfopg2='naefs_ge90pt.${ofile}'," >>namin.wind.prob.$nfhrs
    echo " cfopg3='naefs_ge50pt.${ofile}'," >>namin.wind.prob.$nfhrs
    echo " cfopg4='naefs_geavg.${ofile}'" >>namin.wind.prob.$nfhrs
    echo " cfopg5='naefs_gespr.${ofile}'," >>namin.wind.prob.$nfhrs
    echo " cfopg6='naefs_gemode.${ofile}'," >>namin.wind.prob.$nfhrs
  fi

  if [ "$IFGEFS" = "YES" ]; then
    echo " cfopg1='ge10pt.${ofile}'," >>namin.wind.prob.$nfhrs
    echo " cfopg2='ge90pt.${ofile}'," >>namin.wind.prob.$nfhrs
    echo " cfopg3='ge50pt.${ofile}'," >>namin.wind.prob.$nfhrs
    echo " cfopg4='geavg.${ofile}'" >>namin.wind.prob.$nfhrs
    echo " cfopg5='gespr.${ofile}'," >>namin.wind.prob.$nfhrs
    echo " cfopg6='gemode.${ofile}'," >>namin.wind.prob.$nfhrs
  fi

  if [ "$IFCMCE" = "YES" ]; then
    echo " cfopg1='cmc_ge10pt.${ofile}'," >>namin.wind.prob.$nfhrs
    echo " cfopg2='cmc_ge90pt.${ofile}'," >>namin.wind.prob.$nfhrs
    echo " cfopg3='cmc_ge50pt.${ofile}'," >>namin.wind.prob.$nfhrs
    echo " cfopg4='cmc_geavg.${ofile}'" >>namin.wind.prob.$nfhrs
    echo " cfopg5='cmc_gespr.${ofile}'," >>namin.wind.prob.$nfhrs
    echo " cfopg6='cmc_gemode.${ofile}'," >>namin.wind.prob.$nfhrs
  fi
   
  echo "/" >>namin.wind.prob.$nfhrs

done

cd $DATA/tmpdir_03

if [ -s poescript_wind10m ]; then rm poescript_wind10m; fi

for nfhrs in $hourlist; do
  echo "$EXECrtma/$pgm < namin.wind.prob.$nfhrs >> $pgmout.$nfhrs 2>errfile " >>poescript_wind10m
done

chmod +x poescript_wind10m
startmsg
$APRUN poescript_wind10m
export err=$?; err_chk

wait

set +x
echo " "
echo "Leaving sub script dvrtma_debias_conus_wind10m.sh"
echo " "
set -x

