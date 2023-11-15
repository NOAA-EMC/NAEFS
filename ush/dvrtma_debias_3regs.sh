#!/bin/sh
###################################@##################################
# Script:   dvrtma_debias_3regs.sh
# Abstract: Product downscale ensemble products for 3 regions
# Author:   Bo Cui
# History:  August  2017 - First implementation of this new script 
######################################################################

set -x

echo "----------------------------------------"
echo "Enter sub script dvrtma_debias_3regs.sh"
echo "----------------------------------------"

##############################################
# define exec variable, and entry grib utility 
##############################################

export pgm1=dvrtma_debias_conus

pgmout=output_ds

. prep_step

###
#  step 1: downscale ensemble forecast: tmax and tmin                       
###

mkdir -p $DATA/tmpdir_01
cd $DATA/tmpdir_01           

$USHrtma/dvrtma_debias_tmaxmin.sh 

###
# step 2: downscale ensemble forecast: T2m, 10m U & V, surface pressure
#
#################################################
# set PDS message for grids for different regions
#################################################

if [ "$regid" = "ak" ]; then
  region=alaska
  grid='20 6 0 0 0 0 0 0 1649 1105 40530101 181429000 8 60000000 210000000 2976563 2976563 0 64'
elif [ "$regid" = "conus" ]; then
  region=conus
  grid="30 6 0 0 0 0 0 0 2145 1597 20191999 238445999 8 25000000 265000000 \
      2539703 2539703 0 64 25000000 25000000 -90000000 0"
elif [ "$regid" = "hi" ]; then
  region=hawaii
  grid='10 1 0 6371200 0 0 0 0 321 225 18072699 198474999 56 20000000 23087799 206130999 64 0 2500000 2500000'
elif [ "$regid" = "gu" ]; then
  region=guam
  grid='10 1 0 6371200 0 0 0 0 193 193 12349884 143686538 56 20000000 16794399 148280000 64 0 2500000 2500000'
elif [ "$regid" = "pr" ]; then
  region=puri
  grid='10 1 0 6371200 0 0 0 0 177 129 16828685 291804687 56 20000000 19747399 296027600 64 0 2500000 2500000'
fi

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

    ifile=dvrtma.t${cyc_verf}z.${region}.grib2  

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

    ofile1=${nens}.t${cyc}z.ndgd_${region}f${nfhrs}_part1

###
#  check pgrb2a forecast file, interpolated to grids for different regions
###

    infile=$COMIN/${nens}.t${cyc}z.pgrb2a_bcf${nfhrs} 
    outfile=${nens}.t${cyc}z.pgrb2a_bcf${nfhrs}_temp
    cfile=${nens}.t${cyc}z.pgrb2a_bcf${nfhrs}_2p5

    if [ -s $outfile ]; then
      rm $outfile
    fi

    if [[ ! -s $infile ]]; then
      echo "Input pgrb2a_bc files not available"
      export err=1; err_chk
    fi

    echo ">$outfile"                                                               >> poe_${nens}.${nfhrs}
    echo "$WGRIB2 -match \":PRES\"                 $infile         -grib $outfile" >> poe_${nens}.${nfhrs}
    echo "$WGRIB2 -match \":TMP:\" -match \"2 m \" $infile -append -grib $outfile" >> poe_${nens}.${nfhrs}
    echo "$WGRIB2 -match \":DPT:\" -match \"2 m \" $infile -append -grib $outfile" >> poe_${nens}.${nfhrs}
    echo "$WGRIB2 -match \":RH:\"  -match \"2 m \" $infile -append -grib $outfile" >> poe_${nens}.${nfhrs}
    echo "$WGRIB2 -match \":TCDC\"                 $infile -append -grib $outfile" >> poe_${nens}.${nfhrs}

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

for nens in $outlist; do

  cd $DATA/tmpdir_02/tmpdir_02_$nens

  if [ -s poescript_wgrib_$nens ]; then
    rm poescript_wgrib_$nens
  fi
  for nfhrs in $hourlist; do
    chmod +x poe_${nens}.${nfhrs}
    echo ". ./poe_${nens}.${nfhrs}" >>poescript_wgrib_$nens
  done
  chmod +x poescript_wgrib_$nens
  startmsg
  mpirun.lsf cfp poescript_wgrib_$nens
  export err=$?;$DATA/err_chk

done

for nens in $outlist; do

  cd $DATA/tmpdir_02/tmpdir_02_$nens

  if [ -s poescript_copygb_$nens ]; then 
    rm poescript_copygb_$nens
  fi

  for nfhrs in $hourlist; do

    file_temp=${nens}.t${cyc}z.pgrb2a_bcf${nfhrs}_temp
    outfile=${nens}.t${cyc}z.pgrb2a_bcf${nfhrs}_2p5

    if [ -s $file_temp ]; then
      echo "$COPYGB2 -g \"$grid\" -i1,1 -x $file_temp $outfile" >>poescript_copygb_$nens
    else
      echo "echo "no file of" $file_temp "                     >>poescript_copygb_$nens
    fi

  done

  chmod +x poescript_copygb_$nens
  startmsg
  mpirun.lsf cfp poescript_copygb_$nens
  export err=$?;$DATA/err_chk

done

for nens in $outlist; do

  cd $DATA/tmpdir_02/tmpdir_02_$nens

  if [ -s poescript_${nens} ]; then rm poescript_${nens}; fi

  for nfhrs in $hourlist; do
    cfile=${nens}.t${cyc}z.pgrb2a_bcf${nfhrs}_2p5
    ofile1=${nens}.t${cyc}z.ndgd_${region}f${nfhrs}_part1
    if [ "$nens" = "cmc_gespr" -o "$nens" = "gespr" -o "$nens" = "naefs_gespr" ]; then
      mv $cfile $ofile1
    else
      echo "$EXECrtma/$pgm1 <input.$nfhrs.$nens > $pgmout.$nfhrs.$nens.part1 2> errfile" >>poescript_${nens}
    fi
  done

  if [ "$nens" = "cmc_gespr" -o "$nens" = "gespr" -o "$nens" = "naefs_gespr" ]; then
    echo " copy enseble spread files "
  else
    chmod +x poescript_${nens}
    startmsg
    mpirun.lsf cfp poescript_${nens}
    export err=$?; err_chk
  fi

done 

###
#  step 3: downscale ensemble forecast: wind speed and direction            
###

mkdir -p $DATA/tmpdir_03
cd $DATA/tmpdir_03           

$USHrtma/dvrtma_debias_wind10m.sh 

cd $DATA

##############################################
# combine 3 downscaled forecast files together
##############################################

for nfhrs in $hourlist; do
  for nens in $outlist; do
    ofile1=tmpdir_02/tmpdir_02_$nens/${nens}.t${cyc}z.ndgd_${region}f${nfhrs}_part1
    ofile2=tmpdir_03/${nens}.t${cyc}z.ndgd_${region}f${nfhrs}_part2
    ofile3=tmpdir_01/${nens}.t${cyc}z.ndgd_${region}f${nfhrs}_tmax 
    ofile4=tmpdir_01/${nens}.t${cyc}z.ndgd_${region}f${nfhrs}_tmin 
    ofile=${nens}.t${cyc}z.ndgd2p5_${region}f${nfhrs}.grib2

    if [ -s $ofile ]; then
      rm $ofile
    fi 
    cat $ofile1 $ofile2 >$ofile

    if [ -s $ofile3 ]; then
      cat $ofile3 >>$ofile
    fi
    if [ -s $ofile4 ]; then
      cat $ofile4 >>$ofile
    fi
  done
done

set +x
echo " "
echo "Leaving sub script dvrtma_debias_3regs.sh"
echo " "
set -x
