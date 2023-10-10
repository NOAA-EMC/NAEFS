#!/bin/sh
###################################@##################################
# Script:   dvrtma_debias_conus.sh
# Abstract: Product downscale ensemble products for Conus region
# Author:   Bo Cui
# History:  August  2007 - First implementation of this new script 
#           October 2011 - Second implementation add new variables
#           June    2015 - NAEFS version 5 modified for 2.5km products
######################################################################

set -x

echo "----------------------------------------"
echo "Enter sub script dvrtma_debias_conus.sh"
echo "----------------------------------------"

##############################################
# define exec variable, and entry grib utility 
##############################################

export pgm1=dvrtma_debias_conus

export conus_grid="lambert:-95:25 -121.554007:2145:2539.703 20.191924:1597:2539.703"

pgmout=output_ds

. prep_step

###
#  step 1: downscale ensemble forecast: tmax and tmin                       
###

mkdir -p $DATA/tmpdir_01
cd $DATA/tmpdir_01           

$USHrtma/dvrtma_debias_conus_tmaxmin.sh 

###
# step 2: downscale ensemble forecast: T2m, 10m U & V, surface pressure
#
########################################################
# set PDS message for grids of 2.539km for Conus region
########################################################

#grid="30 6 0 0 0 0 0 0 2145 1377 20191999 238445999 8 25000000 265000000 \
#      2539703 2539703 0 64 25000000 25000000 -90000000 0"

grid="30 6 0 0 0 0 0 0 2145 1597 20191999 238445999 8 25000000 265000000 \
      2539703 2539703 0 64 25000000 25000000 -90000000 0"

###

mkdir -p $DATA/tmpdir_02
cd $DATA/tmpdir_02           

for nens in $outlist; do

  mkdir -p $DATA/tmpdir_02/tmpdir_02_$nens
  cd $DATA/tmpdir_02/tmpdir_02_$nens

  for nfhrs in $hourlist; do

###
#  set the index ( exist of downscaling vector )  as default, 0
###

    cstart=0

###
#  downscaling vector entry
###

    cyc_verf=`$NDATE +$nfhrs $PDY$cyc | cut -c9-10`

    ifile=dvrtma.t${cyc_verf}z.conus_ext_2p5.grib2  

    if [ -s $COM_DV/naefs.$PDY/${cyc_verf}/ndgd_gb2/$ifile ]; then
      cp $COM_DV/naefs.$PDY/${cyc_verf}/ndgd_gb2/$ifile $ifile.f$nfhrs
    elif [ -s $COM_DV/naefs.$PDYm1/${cyc_verf}/ndgd_gb2/$ifile ]; then
      cp $COM_DV/naefs.$PDYm1/${cyc_verf}/ndgd_gb2/$ifile $ifile.f$nfhrs
    elif [ -s $COM_DV/naefs.$PDYm2/${cyc_verf}/ndgd_gb2/$ifile ]; then
      cp $COM_DV/naefs.$PDYm2/${cyc_verf}/ndgd_gb2/$ifile $ifile.f$nfhrs
    elif [ -s $COM_DV/naefs.$PDYm3/${cyc_verf}/ndgd_gb2/$ifile ]; then
      cp $COM_DV/naefs.$PDYm3/${cyc_verf}/ndgd_gb2/$ifile $ifile.f$nfhrs
    elif [ -s $COM_DV/naefs.$PDYm4/${cyc_verf}/ndgd_gb2/$ifile ]; then
      cp $COM_DV/naefs.$PDYm4/${cyc_verf}/ndgd_gb2/$ifile $ifile.f$nfhrs
    elif [ -s $COM_DV/naefs.$PDYm5/${cyc_verf}/ndgd_gb2/$ifile ]; then
      cp $COM_DV/naefs.$PDYm5/${cyc_verf}/ndgd_gb2/$ifile $ifile.f$nfhrs
    elif [ -s $COM_DV/naefs.$PDYm6/${cyc_verf}/ndgd_gb2/$ifile ]; then
      cp $COM_DV/naefs.$PDYm6/${cyc_verf}/ndgd_gb2/$ifile $ifile.f$nfhrs
    elif [ -s $COM_DV/naefs.$PDYm7/${cyc_verf}/ndgd_gb2/$ifile ]; then
      cp $COM_DV/naefs.$PDYm7/${cyc_verf}/ndgd_gb2/$ifile $ifile.f$nfhrs
    else
      echo " There is no Downscaling Vector at " ${cyc_verf}Z 
      cstart=1
    fi

    echo "&message"  >input.$nfhrs.$nens
    echo " icstart=${cstart}," >> input.$nfhrs.$nens

###
#  downscale ensemble forecasting output
###

    ofile1=${nens}.t${cyc}z.ndgd_conusf${nfhrs}_part1

###
#  check pgrb2a forecast file, interpolated on grids of 2.5km for Conus region
###

    infile=$COMIN/${nens}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs} 
    outfile=${nens}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_temp
    cfile=${nens}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5

    if [ -s $outfile ]; then
      rm $outfile
    fi

    if [[ ! -s $infile ]]; then
      echo "Warning !!! Input pgrb2ap5_bc files not available"
      export err=1; err_chk
    fi

    echo "cd $DATA/tmpdir_02/tmpdir_02_$nens"                                      >> poe_${nens}.${nfhrs}
    echo ">$outfile"                                                               >> poe_${nens}.${nfhrs}
    echo "$WGRIB2 -match \":PRES\"                 $infile         -grib $outfile" >> poe_${nens}.${nfhrs}
    echo "$WGRIB2 -match \":TMP:\" -match \"2 m \" $infile -append -grib $outfile" >> poe_${nens}.${nfhrs}
    echo "$WGRIB2 -match \":DPT:\" -match \"2 m \" $infile -append -grib $outfile" >> poe_${nens}.${nfhrs}
    echo "$WGRIB2 -match \":RH:\"  -match \"2 m \" $infile -append -grib $outfile" >> poe_${nens}.${nfhrs}

###
# downscale ensemble forecast: T2m, 10m U & V, surface pressure
###

    if [ "$nens" = "cmc_gespr" -o "$nens" = "gespr" -o "$nens" = "naefs_gespr" ]; then
      echo " this are downscaled ensemble spread "
    else
      echo " cbias=${ifile}.f${nfhrs}," >> input.$nfhrs.$nens
      echo " cfcst=${cfile}," >> input.$nfhrs.$nens
      echo " oprod=${ofile1}," >> input.$nfhrs.$nens
      echo "/" >>input.$nfhrs.$nens
    fi    

  done 
done  

cd $DATA/tmpdir_02

if [ -s poescript_wgrib ]; then
  rm poescript_wgrib
fi

for nens in $outlist; do
  for nfhrs in $hourlist; do
    chmod +x $DATA/tmpdir_02/tmpdir_02_$nens/poe_${nens}.${nfhrs}
    echo "$DATA/tmpdir_02/tmpdir_02_$nens/poe_${nens}.${nfhrs}" >>poescript_wgrib
  done
done

chmod +x poescript_wgrib
startmsg
$APRUN_post poescript_wgrib
export err=$?;err_chk

for nens in $outlist; do

  cd $DATA/tmpdir_02/tmpdir_02_$nens

  if [ -s poescript_copygb_$nens ]; then 
    rm poescript_copygb_$nens
  fi

  for nfhrs in $hourlist; do
    file_temp=${nens}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_temp
    outfile=${nens}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
    if [ -s $file_temp ]; then
#     echo "$COPYGB2 -g \"$grid\" -i1,1 -x $file_temp $outfile" >>poescript_copygb_$nens
      echo "$WGRIB2 $file_temp -new_grid_interpolation bilinear -new_grid $conus_grid $outfile" >>poescript_copygb_$nens
    else
      echo "echo "no file of" $file_temp "                     >>poescript_copygb_$nens
    fi
  done

  chmod +x poescript_copygb_$nens
  startmsg
  $APRUN poescript_copygb_$nens
  export err=$?;err_chk

done

cd $DATA/tmpdir_02

for nens in $outlist; do
  for nfhrs in $hourlist; do
    if [ -s poe_tmpdir02.$nfhrs.$nens ]; then rm poe_tmpdir02.$nfhrs.$nens; fi
    cfile=${nens}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
    ofile1=${nens}.t${cyc}z.ndgd_conusf${nfhrs}_part1
    if [ "$nens" = "cmc_gespr" -o "$nens" = "gespr" -o "$nens" = "naefs_gespr" ]; then
      echo "cd $DATA/tmpdir_02/tmpdir_02_$nens" >>tmpdir_02_$nens/poe_tmpdir02.$nfhrs.$nens
      echo "mv $cfile $ofile1 "                 >>tmpdir_02_$nens/poe_tmpdir02.$nfhrs.$nens
    else
      echo "cd $DATA/tmpdir_02/tmpdir_02_$nens" >>tmpdir_02_$nens/poe_tmpdir02.$nfhrs.$nens
      echo "$EXECrtma/$pgm1 <input.$nfhrs.$nens > $pgmout.$nfhrs.$nens.part1 2> errfile" \
      >>tmpdir_02_$nens/poe_tmpdir02.$nfhrs.$nens
    fi
  done
done

if [ -s poescript_tmpdir_02 ]; then rm poescript_tmpdir_02; fi

for nens in $outlist; do
  for nfhrs in $hourlist; do
    chmod +x tmpdir_02_$nens/poe_tmpdir02.$nfhrs.$nens   
    echo "$DATA/tmpdir_02/tmpdir_02_$nens/poe_tmpdir02.$nfhrs.$nens" >>poescript_tmpdir_02
  done
done

chmod +x poescript_tmpdir_02
startmsg
$APRUN_post poescript_tmpdir_02
export err=$?; err_chk

###
#  step 3: downscale ensemble forecast: wind speed and direction            
###

mkdir -p $DATA/tmpdir_03
cd $DATA/tmpdir_03           

$USHrtma/dvrtma_debias_conus_wind10m.sh 

wait

cd $DATA

##############################################
# combine 3 downscaled forecast files together
##############################################

for nfhrs in $hourlist; do
  for nens in $outlist; do
    if [ -s poe_cat.${nfhrs}.${nens} ]; then rm poe_cat.${nfhrs}.${nens}; fi
    ofile1=tmpdir_02/tmpdir_02_$nens/${nens}.t${cyc}z.ndgd_conusf${nfhrs}_part1
    ofile2=tmpdir_03/${nens}.t${cyc}z.ndgd_conusf${nfhrs}_part2
    ofile3=tmpdir_01/${nens}.t${cyc}z.ndgd_conusf${nfhrs}_tmax 
    ofile4=tmpdir_01/${nens}.t${cyc}z.ndgd_conusf${nfhrs}_tmin 
    ofile=${nens}.t${cyc}z.ndgd2p5_conusf${nfhrs}.grib2_ext

    echo "if [ -s $ofile ]; then rm $ofile; fi"             >>poe_cat.${nfhrs}.${nens}
    echo "cat $ofile1 $ofile2 >$ofile"                      >>poe_cat.${nfhrs}.${nens}
    echo "if [ -s $ofile3 ]; then cat $ofile3 >>$ofile; fi" >>poe_cat.${nfhrs}.${nens}
    echo "if [ -s $ofile4 ]; then cat $ofile4 >>$ofile; fi" >>poe_cat.${nfhrs}.${nens}
  done
done

if [ -s poescript_cat ]; then rm poescript_cat; fi
for nfhrs in $hourlist; do
  for nens in $outlist; do
    chmod +x poe_cat.${nfhrs}.${nens}
    echo ". ./poe_cat.${nfhrs}.${nens}" >>poescript_cat
  done
done

chmod +x poescript_cat
startmsg
$APRUN_post poescript_cat

set +x
echo " "
echo "Leaving sub script dvrtma_debias_conus.sh"
echo " "
set -x
