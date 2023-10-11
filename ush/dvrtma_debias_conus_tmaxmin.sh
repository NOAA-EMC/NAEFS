#!/bin/sh
##################################################################################
# Script:   dvrtma_debias_conus_tmaxmin.sh
# Abstract: Downscale Ensemble Products on Conus Region for Variables Tmax & Tmin                    
# Author:   Bo Cui
# History:  October 2013 - First implementation of this new script
#           June    2015 - NAEFS version 5 modified for 2.5km products
##################################################################################

echo "----------------------------------------------------------------"
echo "dvrtma_debias_conus_tmaxmin.sh: downscale tmax & tmin on Conus"
echo "----------------------------------------------------------------"

set -x

##############################################
# define exec variable, and entry grib utility
##############################################

pgm=dvrtma_debias_conus_tmaxmin
pgmout=output_ds_tmaxmin 

########################################
#  define ensemble members and lead time
########################################

hourlist="    006 012 018 024 030 036 042 048 054 060 066 072 078 084 090 096 \
          102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
          204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

if [ "$IFNAEFS" = "YES" ]; then
  if [ "$cyc" = "00" -o "$cyc" = "12" ]; then
    memberlist="$memberlist_cmc $memberlist_ncep "
  fi
  if [ "$cyc" = "06" -o "$cyc" = "18" ]; then
    memberlist="$memberlist_ncep"
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
# set PDS message for grids of 2.5km for Conus region
########################################################

#grid="30 6 0 0 0 0 0 0 2145 1377 20191999 238445999 8 25000000 265000000 \
#      2539703 2539703 0 64 25000000 25000000 -90000000 0"

grid="30 6 0 0 0 0 0 0 2145 1597 20191999 238445999 8 25000000 265000000 \
      2539703 2539703 0 64 25000000 25000000 -90000000 0"

###################################################################################
# Adjust CMC ensemble forecast, all members are shift to NCEP analysis
# Input CMC Ensemble forecast, all members are saved in one file for one lead time 
###################################################################################

if [ "$IFNAEFS" = "YES" -o  "$IFCMCE" = "YES" ]; then

  if [ "$cyc" = "00" -o "$cyc" = "12" ]; then
 
    $USHrtma/cmce_adjust_tmaxmin_conus.sh

    if [ -s poescript_cmce ]; then rm poescript_cmce; fi

    for nfhrs in $hourlist; do
      file_temp=cmce.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_temp
      outfile=cmce.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ -s $file_temp ]; then
        echo "$COPYGB2 -g \"$grid\" -i1,1 -x $file_temp $outfile" >>poescript_cmce
#echo "$WGRIB2 $file_temp -new_grid_interpolation bilinear -new_grid $conus_grid $outfile" >>poescript_cmce
      else
        echo "echo "no file of" $file_temp "                     >>poescript_cmce
      fi
    done
#   chmod +x poescript_cmce
#   startmsg
#   $APRUN poescript_cmce
#   export err=$?; err_chk
#   wait

  fi
fi

###################################################################################
# input NCEP Ensemble forecast, all members are saved in one file for one lead time 
###################################################################################

if [ "$IFNAEFS" = "YES" -o  "$IFGEFS" = "YES" ]; then

  for nfhrs in $hourlist; do
    if [ -s poe.$nfhrs ]; then rm poe.$nfhrs; fi
    file_temp=gefs.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_temp
    echo ">$file_temp" >> poe.$nfhrs
    for mem in ${memberlist_ncep}; do
      infile=$COM_NCEP/gefs.$PDY/${cyc}/pgrb2ap5_bc/ge${mem}.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}
      if [ -s $infile ]; then
        echo "$WGRIB2 -match \":TMAX:\" -match \"2 m\" $infile -append -grib $file_temp" >> poe.$nfhrs
        echo "$WGRIB2 -match \":TMIN:\" -match \"2 m\" $infile -append -grib $file_temp" >> poe.$nfhrs
        echo "$WGRIB2 -match \":TMP:\"  -match \"2 m\" $infile -append -grib $file_temp" >> poe.$nfhrs
      else
        echo "echo \"File $infile is missing\"" >> poe.$nfhrs
      fi
    done
  done

  if [ -s poescript_gefs_wgrib ]; then rm poescript_gefs_wgrib; fi
  for nfhrs in $hourlist; do
    chmod +x poe.$nfhrs              
    echo ". ./poe.$nfhrs" >> poescript_gefs_wgrib
  done

  chmod +x poescript_gefs_wgrib
  startmsg
  $APRUN poescript_gefs_wgrib
  export err=$?; err_chk
  wait

  if [ -s poescript_gefs ]; then rm poescript_gefs; fi

  for nfhrs in $hourlist; do
    file_temp=gefs.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_temp
    outfile=gefs.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
    if [ -s $file_temp ]; then
      echo "$COPYGB2 -g \"$grid\" -i1,1 -x $file_temp $outfile" >>poescript_gefs
#echo "$WGRIB2 $file_temp -new_grid_interpolation bilinear -new_grid $conus_grid $outfile" >>poescript_gefs
    else
      echo "echo "no file of" $file_temp "                     >>poescript_gefs
    fi
  done

  if [ "$IFNAEFS" = "YES" -o  "$IFCMCE" = "YES" ]; then
    if [ "$cyc" = "00" -o "$cyc" = "12" ]; then
      if [ -s poescript_cmce ]; then
        cat poescript_cmce >>poescript_gefs
      fi
    fi
  fi

  chmod +x poescript_gefs
  startmsg
# $APRUN poescript_gefs
  $APRUN_post poescript_gefs
  export err=$?; err_chk
  wait

fi

#####################################
# Combine GEFS CMCE ensemble together
#####################################

if [ "$IFNAEFS" = "YES" ]; then
  if [ "$cyc" = "00" -o "$cyc" = "12" ]; then
    for nfhrs in $hourlist; do
      infile1=gefs.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      infile2=cmce.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      outfile=$out.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      >$outfile
      cat $infile1 $infile2 >$outfile     
    done
  fi
  if [ "$cyc" = "06" -o "$cyc" = "18" ]; then
    for nfhrs in $hourlist; do
      infile1=gefs.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      outfile=$out.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      mv $infile1 $outfile
    done
  fi
fi

#####################################
# input four downscaling vector files 
#####################################

for cycle in 00 06 12 18; do

    ifile=dvrtma.t${cycle}z.conus_ext_2p5.grib2 

    if [ -s $COM_DV/naefs.$PDY/${cycle}/ndgd_gb2/$ifile ]; then
      cp $COM_DV/naefs.$PDY/${cycle}/ndgd_gb2/$ifile $ifile
    elif [ -s $COM_DV/naefs.$PDYm1/${cycle}/ndgd_gb2/$ifile ]; then
      cp $COM_DV/naefs.$PDYm1/${cycle}/ndgd_gb2/$ifile $ifile
    elif [ -s $COM_DV/naefs.$PDYm2/${cycle}/ndgd_gb2/$ifile ]; then
      cp $COM_DV/naefs.$PDYm2/${cycle}/ndgd_gb2/$ifile $ifile
    elif [ -s $COM_DV/naefs.$PDYm3/${cycle}/ndgd_gb2/$ifile ]; then
      cp $COM_DV/naefs.$PDYm3/${cycle}/ndgd_gb2/$ifile $ifile
    elif [ -s $COM_DV/naefs.$PDYm4/${cycle}/ndgd_gb2/$ifile ]; then
      cp $COM_DV/naefs.$PDYm4/${cycle}/ndgd_gb2/$ifile $ifile
    elif [ -s $COM_DV/naefs.$PDYm5/${cycle}/ndgd_gb2/$ifile ]; then
      cp $COM_DV/naefs.$PDYm5/${cycle}/ndgd_gb2/$ifile $ifile
    elif [ -s $COM_DV/naefs.$PDYm6/${cycle}/ndgd_gb2/$ifile ]; then
      cp $COM_DV/naefs.$PDYm6/${cycle}/ndgd_gb2/$ifile $ifile
    elif [ -s $COM_DV/naefs.$PDYm7/${cycle}/ndgd_gb2/$ifile ]; then
      cp $COM_DV/naefs.$PDYm7/${cycle}/ndgd_gb2/$ifile $ifile
    else
      echo " There is no Bias Estimation at " ${cycle}Z 
    fi

done

###############################################################
# set three data files used for judge tmax for each day 
# set forecast day number available for 4 cycles (15 or 16 days)
###############################################################

case $cyc in
  00) ndays=15;echo $ndays;;
  06) ndays=15;echo $ndays;;
  12) ndays=16;echo $ndays;;
  18) ndays=15;echo $ndays;;
esac

iday=0

while [ $iday -le $ndays ]; do

  ifhr=`expr $iday \* 24`
  echo "day=" $iday $ifhr

  if [ -s namin.day${iday}_tmax ]; then
    rm namin.day${iday}_tmax
  fi

  echo " &namens" >>namin.day${iday}_tmax

  ifile=0

  for cent in $centerlist; do

    if [ $cyc -eq 06 ]; then

      nfhrs=`expr $ifhr + 0 `
      ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -eq 0 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf000_2p5
      fi   
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   

      nfhrs=`expr $ifhr + 06 `
      ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   

      nfhrs=`expr $ifhr + 12 `
      ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   

      nfhrs=`expr $ifhr + 18 `
      ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   

      nfhrs=`expr $ifhr + 24 `
      ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   

      nfhrs=`expr $ifhr + 24 `
      ofile=t${cyc}z.ndgd_conusf${nfhrs}_tmax 
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ofile=t${cyc}z.ndgd_conusf0${nfhrs}_tmax                  
      fi   

    fi

    if [ $cyc -eq 12 ]; then

      nfhrs=`expr $ifhr - 6 `
      ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 0 ]; then
        ifile0=
      fi   

      nfhrs=`expr $ifhr + 0 `
      ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -eq 0 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf000_2p5
      fi   
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   

      nfhrs=`expr $ifhr + 6 `
      ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -gt 384 ]; then
        ifile2=
      fi   

      nfhrs=`expr $ifhr + 12 `
      ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -gt 384 ]; then
        ifile3=
      fi   

      nfhrs=`expr $ifhr + 18 `
      ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -gt 384 ]; then
        ifile4=
      fi   

      nfhrs=`expr $ifhr + 18 `
      ofile=t${cyc}z.ndgd_conusf${nfhrs}_tmax 
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ofile=t${cyc}z.ndgd_conusf0${nfhrs}_tmax                  
      fi   
      if [ $nfhrs -gt 384 ]; then
        ofile=
      fi   
#     if [ $nfhrs -le 18 ]; then
#       ofile=
#     fi   

    fi

    if [ $cyc -eq 18 ]; then

      nfhrs=`expr $ifhr - 12`
      ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 0 ]; then
        ifile0=
      fi   

      nfhrs=`expr $ifhr - 6 `
      ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 0 ]; then
        ifile1=
      fi   

      nfhrs=`expr $ifhr + 0 `
      ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -eq 0 ]; then
        ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf000_2p5
      fi   

      nfhrs=`expr $ifhr + 6 `
      ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -gt 384 ]; then
        ifile3=
      fi   

      nfhrs=`expr $ifhr + 12 `
      ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -gt 384 ]; then
        ifile4=
      fi   

      nfhrs=`expr $ifhr + 12 `
      ofile=t${cyc}z.ndgd_conusf${nfhrs}_tmax 
      if [ $nfhrs -lt 100 -a $nfhrs -gt 12 ]; then
        ofile=t${cyc}z.ndgd_conusf0${nfhrs}_tmax
      fi   
      if [ $nfhrs -gt 384 ]; then
        ofile=
      fi   
      if [ $nfhrs -le 12 ]; then
        ofile=
      fi   

    fi

    if [ $cyc -eq 00 ]; then

      nfhrs=`expr $ifhr - 18`
      ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 0 ]; then
        ifile0=
      fi   

      nfhrs=`expr $ifhr - 12`
      ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 0 ]; then
        ifile1=
      fi   

      nfhrs=`expr $ifhr - 6 `
      ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 0 ]; then
        ifile2=
      fi   

      nfhrs=`expr $ifhr + 0 `
      ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -eq 0 ]; then
        ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf000_2p5
      fi   

      nfhrs=`expr $ifhr + 6 `
      ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -gt 384 ]; then
        ifile4=
      fi   

      nfhrs=`expr $ifhr + 6 `
      ofile=t${cyc}z.ndgd_conusf${nfhrs}_tmax 
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ofile=t${cyc}z.ndgd_conusf0${nfhrs}_tmax                 
      fi   
      if [ $nfhrs -gt 384 ]; then
        ofile=
      fi   
      if [ $nfhrs -le 06 ]; then
        ofile=
      fi   

    fi   

    echo "ifile0=" $ifile0
    echo "ifile1=" $ifile1
    echo "ifile2=" $ifile2
    echo "ifile3=" $ifile3 
    echo "ifile4=" $ifile4 
    echo "ofile=" $ofile 

##########################################
# judge if all 5 input files are available
##########################################

    iskip=1

    if [ "$ifile0" = "" ]; then
      iskip=0
    fi
    (( ifile = ifile + 1 ))
    if [ ! -s $ifile0 ]; then
      iskip=0
    fi
    echo " cfipg($ifile)='$ifile0'," >>namin.day${iday}_tmax
    echo " iskip($ifile)=${iskip}," >>namin.day${iday}_tmax

    iskip=1
    if [ "$ifile1" = "" ]; then
      iskip=0
    fi
    (( ifile = ifile + 1 ))
    if [ ! -s $ifile1 ]; then
      iskip=0
    fi
    echo " cfipg($ifile)='$ifile1'," >>namin.day${iday}_tmax
    echo " iskip($ifile)=${iskip}," >>namin.day${iday}_tmax

    iskip=1
    if [ "$ifile2" = "" ]; then
      iskip=0
    fi
    (( ifile = ifile + 1 ))
    if [ ! -s $ifile2 ]; then
      iskip=0
    fi
    echo " cfipg($ifile)='$ifile2'," >>namin.day${iday}_tmax
    echo " iskip($ifile)=${iskip}," >>namin.day${iday}_tmax

    iskip=1
    if [ "$ifile3" = "" ]; then
      iskip=0
    fi
    (( ifile = ifile + 1 ))
    if [ ! -s $ifile3 ]; then
      iskip=0
    fi
    echo " cfipg($ifile)='$ifile3'," >>namin.day${iday}_tmax
    echo " iskip($ifile)=${iskip}," >>namin.day${iday}_tmax

    iskip=1
    if [ "$ifile4" = "" ]; then
      iskip=0
    fi
    (( ifile = ifile + 1 ))
    if [ ! -s $ifile4 ]; then
      iskip=0
    fi
    echo " cfipg($ifile)='$ifile4'," >>namin.day${iday}_tmax
    echo " iskip($ifile)=${iskip}," >>namin.day${iday}_tmax

  done

###########################################################
# set 4 downscaling vector input files for tmax downscaling 
###########################################################

  ifile_dv1=dvrtma.t06z.conus_ext_2p5.grib2
  ifile_dv2=dvrtma.t12z.conus_ext_2p5.grib2
  ifile_dv3=dvrtma.t18z.conus_ext_2p5.grib2
  ifile_dv4=dvrtma.t00z.conus_ext_2p5.grib2

  echo " nfiles=${ifile}," >>namin.day${iday}_tmax

  echo " cfipgdv1='${ifile_dv1}'," >>namin.day${iday}_tmax
  echo " cfipgdv2='${ifile_dv2}'," >>namin.day${iday}_tmax
  echo " cfipgdv3='${ifile_dv3}'," >>namin.day${iday}_tmax
  echo " cfipgdv4='${ifile_dv4}'," >>namin.day${iday}_tmax

#########################################
# set up output files for downscaled tmax
#########################################

  oskip=1
  if [ "$ofile" = "" ]; then
    oskip=0
  fi

  if [ "$IFNAEFS" = "YES" ]; then
    echo " cfopg1='naefs_ge10pt.${ofile}'," >>namin.day${iday}_tmax
    echo " cfopg2='naefs_ge90pt.${ofile}'," >>namin.day${iday}_tmax
    echo " cfopg3='naefs_ge50pt.${ofile}'," >>namin.day${iday}_tmax
    echo " cfopg4='naefs_geavg.${ofile}'" >>namin.day${iday}_tmax
    echo " cfopg5='naefs_gespr.${ofile}'," >>namin.day${iday}_tmax
    echo " cfopg6='naefs_gemode.${ofile}'," >>namin.day${iday}_tmax
  fi

  if [ "$IFGEFS" = "YES" ]; then
    echo " cfopg1='ge10pt.${ofile}'," >>namin.day${iday}_tmax
    echo " cfopg2='ge90pt.${ofile}'," >>namin.day${iday}_tmax
    echo " cfopg3='ge50pt.${ofile}'," >>namin.day${iday}_tmax
    echo " cfopg4='geavg.${ofile}'" >>namin.day${iday}_tmax
    echo " cfopg5='gespr.${ofile}'," >>namin.day${iday}_tmax
    echo " cfopg6='gemode.${ofile}'," >>namin.day${iday}_tmax
  fi

  if [ "$IFCMCE" = "YES" ]; then
    echo " cfopg1='cmc_ge10pt.${ofile}'," >>namin.day${iday}_tmax
    echo " cfopg2='cmc_ge90pt.${ofile}'," >>namin.day${iday}_tmax
    echo " cfopg3='cmc_ge50pt.${ofile}'," >>namin.day${iday}_tmax
    echo " cfopg4='cmc_geavg.${ofile}'" >>namin.day${iday}_tmax
    echo " cfopg5='cmc_gespr.${ofile}'," >>namin.day${iday}_tmax
    echo " cfopg6='cmc_gemode.${ofile}'," >>namin.day${iday}_tmax
  fi

  echo " oskip=$oskip," >>namin.day${iday}_tmax
  echo " variable='tmax'," >>namin.day${iday}_tmax
  echo " tmems=${tmems}," >>namin.day${iday}_tmax

###############################################################
### set the start (fhrst) and end (fhrend) time for output tmax
###############################################################

  fhrst=`expr $nfhrs - 24 `
  fhrend=$nfhrs
  if [ $fhrst -le 0 ]; then
    fhrst=0
  fi
  if [ $nfhrs -gt 384 ]; then
    fhrend=384   
  fi
  echo " fhrst=$fhrst," >>namin.day${iday}_tmax
  echo " fhrend=$fhrend," >>namin.day${iday}_tmax
  echo " /" >>namin.day${iday}_tmax

  iday=`expr $iday + 1`

done

iday=0
icount=0

if [ -s poescript_tmax ]; then rm poescript_tmax; fi

while [ $iday -le 63 ]; do
  if [ $icount -le $ndays ]; then
    echo "$EXECrtma/$pgm < namin.day${iday}_tmax >> $pgmout.day${iday}_tmax 2> errfile" >>poescript_tmax
  else
    echo "echo "no more jobs for tmax calculation" " >>poescript_tmax
  fi
  iday=`expr $iday + 1`
  icount=`expr $icount + 1`
done

#chmod +x poescript_tmax
#$APRUN poescript_tmax
#export err=$?; err_chk

#wait

################################################################
# set three data files used for judge tmin for each day 
# set forecast day number available for 4 cycles (15 or 16 days)
################################################################

ofile=
ifile0=
ifile1=
ifile2=
ifile3=
ifile4=
ifile_dv1=
ifile_dv2=
ifile_dv3=
ifile_dv4=

case $cyc in
  00) ndays=15;echo $ndays;;
  06) ndays=15;echo $ndays;;
  12) ndays=15;echo $ndays;;
  18) ndays=15;echo $ndays;;
esac

iday=0

while [ $iday -le $ndays ]; do

  ifhr=`expr $iday \* 24`
  echo "day=" $iday $ifhr $cyc

  echo " &namens" >>namin.day${iday}_tmin

  ifile=0

  for cent in $centerlist; do

    if [ $cyc -eq 06 ]; then

      nfhrs=`expr $ifhr - 12`
      ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 0 ]; then
        ifile0=
      fi   

      nfhrs=`expr $ifhr - 6 `
      ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 0 ]; then
        ifile1=
      fi   

      nfhrs=`expr $ifhr + 0 `
      ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -eq 0 ]; then
        ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf000_2p5
      fi   

      nfhrs=`expr $ifhr + 6 `
      ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -gt 384 ]; then
        ifile3=
      fi   

      nfhrs=`expr $ifhr + 12 `
      ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -gt 384 ]; then
        ifile4=
      fi   

      nfhrs=`expr $ifhr + 12 `
      ofile=t${cyc}z.ndgd_conusf${nfhrs}_tmin 
      if [ $nfhrs -lt 100 -a $nfhrs -gt 12 ]; then
        ofile=t${cyc}z.ndgd_conusf0${nfhrs}_tmin                  
      fi   
      if [ $nfhrs -gt 384 ]; then
        ofile=
      fi   
      if [ $nfhrs -le 12 ]; then
        ofile=
      fi

    fi

    if [ $cyc -eq 12 ]; then

      nfhrs=`expr $ifhr - 18`
      ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 0 ]; then
        ifile0=
      fi   

      nfhrs=`expr $ifhr - 12`
      ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 0 ]; then
        ifile1=
      fi   

      nfhrs=`expr $ifhr - 6 `
      ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 0 ]; then
        ifile2=
      fi   

      nfhrs=`expr $ifhr + 0 `
      ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -eq 0 ]; then
        ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf000_2p5
      fi   

      nfhrs=`expr $ifhr + 6 `
      ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -gt 384 ]; then
        ifile4=
      fi   

      nfhrs=`expr $ifhr + 6 `
      ofile=t${cyc}z.ndgd_conusf${nfhrs}_tmin 
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ofile=t${cyc}z.ndgd_conusf0${nfhrs}_tmin              
      fi   
      if [ $nfhrs -gt 384 ]; then
        ofile=t${cyc}z.ndgd_conusf384_tmin 
      fi   
      if [ $nfhrs -le 06 ]; then
        ofile=
      fi

    fi   

    if [ $cyc -eq 18 ]; then

      nfhrs=`expr $ifhr + 0 `
      ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -eq 0 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf000_2p5
      fi   

      nfhrs=`expr $ifhr + 06 `
      ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   

      nfhrs=`expr $ifhr + 12 `
      ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   

      nfhrs=`expr $ifhr + 18 `
      ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   

      nfhrs=`expr $ifhr + 24 `
      ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   

      nfhrs=`expr $ifhr + 24 `
      ofile=t${cyc}z.ndgd_conusf${nfhrs}_tmin 
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ofile=t${cyc}z.ndgd_conusf0${nfhrs}_tmin                 
      fi   

    fi

    if [ $cyc -eq 00 ]; then

      nfhrs=`expr $ifhr - 6 `
      ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile0=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 0 ]; then
        ifile0=
      fi   

      nfhrs=`expr $ifhr + 0 `
      ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -eq 0 ]; then
        ifile1=$cent.t${cyc}z.pgrb2a.0p50_bcf000_2p5
      fi   

      nfhrs=`expr $ifhr + 6 `
      ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 10 -a $nfhrs -gt 0 ]; then
        ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf00${nfhrs}_2p5
      fi   
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile2=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -gt 384 ]; then
        ifile2=
      fi   

      nfhrs=`expr $ifhr + 12 `
      ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile3=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -gt 384 ]; then
        ifile3=
      fi   

      nfhrs=`expr $ifhr + 18 `
      ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}_2p5
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ifile4=$cent.t${cyc}z.pgrb2a.0p50_bcf0${nfhrs}_2p5
      fi   
      if [ $nfhrs -gt 384 ]; then
        ifile4=
      fi   

      nfhrs=`expr $ifhr + 18 `
      ofile=t${cyc}z.ndgd_conusf${nfhrs}_tmin 
      if [ $nfhrs -lt 100 -a $nfhrs -gt 10 ]; then
        ofile=t${cyc}z.ndgd_conusf0${nfhrs}_tmin                    
      fi   
      if [ $nfhrs -gt 384 ]; then
        ofile=
      fi   
#     if [ $nfhrs -le 18 ]; then
#       ofile=
#     fi

    fi   

    echo "ifile0=" $ifile0
    echo "ifile1=" $ifile1
    echo "ifile2=" $ifile2
    echo "ifile3=" $ifile3 
    echo "ifile4=" $ifile4 
    echo "ofile=" $ofile 

##########################################
# judge if all 5 input files are available
##########################################

    iskip=1
    if [ "$ifile0" = "" ]; then
      iskip=0
    fi
    (( ifile = ifile + 1 ))
    if [ ! -s $ifile0 ]; then
      iskip=0
    fi
    echo " cfipg($ifile)='$ifile0'," >>namin.day${iday}_tmin
    echo " iskip($ifile)=${iskip}," >>namin.day${iday}_tmin

    iskip=1
    if [ "$ifile1" = "" ]; then
      iskip=0
    fi
    (( ifile = ifile + 1 ))
    if [ ! -s $ifile1 ]; then
      iskip=0
    fi
    echo " cfipg($ifile)='$ifile1'," >>namin.day${iday}_tmin
    echo " iskip($ifile)=${iskip}," >>namin.day${iday}_tmin

    iskip=1
    if [ "$ifile2" = "" ]; then
      iskip=0
    fi
    (( ifile = ifile + 1 ))
    if [ ! -s $ifile2 ]; then
      iskip=0
    fi
    echo " cfipg($ifile)='$ifile2'," >>namin.day${iday}_tmin
    echo " iskip($ifile)=${iskip}," >>namin.day${iday}_tmin

    iskip=1
    if [ "$ifile3" = "" ]; then
      iskip=0
    fi
    (( ifile = ifile + 1 ))
    if [ ! -s $ifile3 ]; then
      iskip=0
    fi
    echo " cfipg($ifile)='$ifile3'," >>namin.day${iday}_tmin
    echo " iskip($ifile)=${iskip}," >>namin.day${iday}_tmin

    iskip=1
    if [ "$ifile4" = "" ]; then
      iskip=0
    fi
    (( ifile = ifile + 1 ))
    if [ ! -s $ifile4 ]; then
      iskip=0
    fi
    echo " cfipg($ifile)='$ifile4'," >>namin.day${iday}_tmin
    echo " iskip($ifile)=${iskip}," >>namin.day${iday}_tmin

  done

###########################################################
# set 4 downscaling vector input files for tmin downscaling
###########################################################

  ifile_dv1=dvrtma.t18z.conus_ext_2p5.grib2 
  ifile_dv2=dvrtma.t00z.conus_ext_2p5.grib2 
  ifile_dv3=dvrtma.t06z.conus_ext_2p5.grib2 
  ifile_dv4=dvrtma.t12z.conus_ext_2p5.grib2 

  echo " nfiles=${ifile}," >>namin.day${iday}_tmin

  echo " cfipgdv1='${ifile_dv1}'," >>namin.day${iday}_tmin
  echo " cfipgdv2='${ifile_dv2}'," >>namin.day${iday}_tmin
  echo " cfipgdv3='${ifile_dv3}'," >>namin.day${iday}_tmin
  echo " cfipgdv4='${ifile_dv4}'," >>namin.day${iday}_tmin

#########################################
# set up output files for downscaled tmin
#########################################

  oskip=1
  if [ "$ofile" = "" ]; then
    oskip=0
  fi

  if [ "$IFNAEFS" = "YES" ]; then
    echo " cfopg1='naefs_ge10pt.${ofile}'," >>namin.day${iday}_tmin
    echo " cfopg2='naefs_ge90pt.${ofile}'," >>namin.day${iday}_tmin
    echo " cfopg3='naefs_ge50pt.${ofile}'," >>namin.day${iday}_tmin
    echo " cfopg4='naefs_geavg.${ofile}'" >>namin.day${iday}_tmin
    echo " cfopg5='naefs_gespr.${ofile}'," >>namin.day${iday}_tmin
    echo " cfopg6='naefs_gemode.${ofile}'," >>namin.day${iday}_tmin
  fi

  if [ "$IFGEFS" = "YES" ]; then
    echo " cfopg1='ge10pt.${ofile}'," >>namin.day${iday}_tmin
    echo " cfopg2='ge90pt.${ofile}'," >>namin.day${iday}_tmin
    echo " cfopg3='ge50pt.${ofile}'," >>namin.day${iday}_tmin
    echo " cfopg4='geavg.${ofile}'" >>namin.day${iday}_tmin
    echo " cfopg5='gespr.${ofile}'," >>namin.day${iday}_tmin
    echo " cfopg6='gemode.${ofile}'," >>namin.day${iday}_tmin
  fi

  if [ "$IFCMCE" = "YES" ]; then
    echo " cfopg1='cmc_ge10pt.${ofile}'," >>namin.day${iday}_tmin
    echo " cfopg2='cmc_ge90pt.${ofile}'," >>namin.day${iday}_tmin
    echo " cfopg3='cmc_ge50pt.${ofile}'," >>namin.day${iday}_tmin
    echo " cfopg4='cmc_geavg.${ofile}'" >>namin.day${iday}_tmin
    echo " cfopg5='cmc_gespr.${ofile}'," >>namin.day${iday}_tmin
    echo " cfopg6='cmc_gemode.${ofile}'," >>namin.day${iday}_tmin
  fi

  echo " oskip=$oskip," >>namin.day${iday}_tmin
  echo " variable='tmin'," >>namin.day${iday}_tmin
  echo " tmems=${tmems}," >>namin.day${iday}_tmin

###############################################################
### set the start (fhrst) and end (fhrend) time for output tmin
###############################################################

  fhrst=`expr $nfhrs - 24 `
  fhrend=$nfhrs
  if [ $fhrst -le 0 ]; then
    fhrst=0
  fi
  if [ $nfhrs -gt 384 ]; then
    fhrend=384   
  fi
  echo " fhrst=$fhrst," >>namin.day${iday}_tmin
  echo " fhrend=$fhrend," >>namin.day${iday}_tmin
  echo " /" >>namin.day${iday}_tmin

  iday=`expr $iday + 1`

done

iday=0
icount=0

if [ -s poescript_tmin ]; then rm poescript_tmin; fi

while [ $iday -le 63 ]; do
  if [ $icount -le $ndays ]; then
    echo "$EXECrtma/$pgm  <namin.day${iday}_tmin > $pgmout.day${iday}_tmin  2> errfile" >>poescript_tmin
  else
    echo "echo "no more jobs for tmin calculation" " >>poescript_tmin
  fi
  iday=`expr $iday + 1`
  icount=`expr $icount + 1`
done

cat poescript_tmin poescript_tmax > poescript_tminmax 
chmod +x poescript_tminmax
$APRUN poescript_tminmax
export err=$?; err_chk

#chmod +x poescript_tmin
#$APRUN poescript_tmin
#export err=$?; err_chk

wait

set +x
echo " "
echo "Leaving sub script dvrtma_debias_conus_tmaxmin.sh"
echo " "
set -x

