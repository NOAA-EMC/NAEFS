#################################################################
# Script: gefs_bias_reforecast.sh
# Abstract: this script generate reforecast bias estimation files    
# Author: Bo Cui ---- Oct. 2016
#################################################################

set -x

mkdir -p $DATA/dir_rfbias
cd $DATA/dir_rfbias

####################################
# define exec variable, and hourlist
####################################

#hourlist="    003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 \
#          051 054 057 060 063 066 069 072 075 078 081 084 087 090 093 096 099 \
#          102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 \
#          153 156 159 162 165 168 171 174 177 180 183 186 189 192 198 204 \
#          210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
#          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

##################################################################
# Step 1: separate reforecast bias according to forecast lead time                       
##################################################################

MD=`echo $PDY | cut -c5-8`

for nfhrs in $hourlist; do
  if [ -s poe_rfbias_${nfhrs} ]; then
    rm poe_rfbias_${nfhrs}   
  fi
done

for nfhrs in $hourlist; do

  infile=$FIXgefs/rfbias_1d.2015${MD}00
  outfile=rfbias_1d.${MD}00.f${nfhrs}

  if [ -s $outfile ]; then
    rm $outfile
  fi

  if [ ! -s $infile ]; then
    echo "Input reforecast bias file not available"
  fi

  if [ $nfhrs -le 99 ]; then
    fhr=`expr $nfhrs - 0 `
  else
    fhr=$nfhrs
  fi    

  rem=`echo "${nfhrs}%6" | bc`

  if [ $rem -ne 0 ]; then
    echo "$nfhrs is odd number, no need to separate reforecast bias"
    echo "echo "no reforecast bias for lead time " $nfhrs "         >> poe_rfbias_${nfhrs}    
  else
    echo "$nfhrs is even number, need to separate reforecast bias"
    if [ -s $infile ]; then
      echo ">$outfile"                                              >> poe_rfbias_${nfhrs}
      echo "$WGRIB2 -match \":${fhr} hour\" $infile -grib $outfile" >> poe_rfbias_${nfhrs}
    else
      echo "echo "no file of" $infile "                             >> poe_rfbias_${nfhrs}    
    fi
  fi

done 

if [ -s poescript_wgrib_rfbias ]; then
  rm poescript_wgrib_rfbias
fi

for nfhrs in $hourlist; do
  chmod +x poe_rfbias_${nfhrs}
  echo "poe_rfbias_${nfhrs}" >> poescript_wgrib_rfbias 
done

chmod +x poescript_wgrib_rfbias

startmsg
$APRUN poescript_wgrib_rfbias
export err=$?;err_chk
wait

#####################################################
# Step 2: interpolate reforecast bias from 1d to 0.5d
#####################################################

grid="0 6 0 0 0 0 0 0 720 361 0 0 90000000 0 48 -90000000 359500000 500000 500000 0"

if [ -s poescript_copygb_rfbias ]; then 
  rm poescript_copygb_rfbias
fi

for nfhrs in $hourlist; do

  infile=rfbias_1d.${MD}00.f${nfhrs}                        
  outfile=rfbias_0p50.${MD}00.f${nfhrs}                          

  if [ -s $infile ]; then
    echo "$COPYGB2 -g \"$grid\" -i1 -x $infile $outfile" >> poescript_copygb_rfbias
  else
    echo "echo "no file of" $infile "                    >> poescript_copygb_rfbias
  fi

done

chmod +x poescript_copygb_rfbias

startmsg
$APRUN poescript_copygb_rfbias
export err=$?;err_chk
wait

########################################################
# Step 3 interpolate reforecast bias for 3hrly lead time
########################################################

pgm=gefs_bias_gen

for nfhrs in $hourlist; do

  nfile=0

  if [ -s namin_rfbias_${nfhrs} ]; then
    rm namin_rfbias_${nfhrs}
  fi

  rem=`echo "${nfhrs}%6" | bc`

  if [ $rem -eq 0 ]; then
    echo "$nfhrs is even number, no need to calculate reforecast bias"
  else
    echo "$nfhrs is odd number, need to calculate reforecast bias"

    echo " &namens" >>namin_rfbias_${nfhrs}

    nfhrsm03=`expr $nfhrs - 03`
    nfhrsp03=`expr $nfhrs + 03`

    iskip=1
    file=rfbias_0p50.${MD}00.f${nfhrsm03}
    if [ $nfhrsm03 -lt 100 -a $nfhrsm03 -gt 10 ];then
      file=rfbias_0p50.${MD}00.f0${nfhrsm03}
    elif [ $nfhrsm03 -lt 10 -a $nfhrsm03 -gt 0 ];then
      file=rfbias_0p50.${MD}00.f00${nfhrsm03}
    elif [ $nfhrsm03 -eq 0 ];then
      file=rfbias_0p50.${MD}00.f000
    fi
    if [ -s $file ]; then
      iskip=0
      (( nfile = nfile + 1 ))
    fi
    echo " cfipg(1)='${file}'," >>namin_rfbias_${nfhrs}
    echo " iskip(1)=${iskip},"  >>namin_rfbias_${nfhrs}

    iskip=1
    file=rfbias_0p50.${MD}00.f${nfhrsp03}
    if [ $nfhrsp03 -lt 100 -a $nfhrsp03 -gt 10 ];then
      file=rfbias_0p50.${MD}00.f0${nfhrsp03}
    elif [ $nfhrsp03 -lt 10 -a $nfhrsp03 -gt 0 ];then
      file=rfbias_0p50.${MD}00.f00${nfhrsp03}
    elif [ $nfhrsp03 -eq 0 ];then
      file=rfbias_0p50.${MD}00.f000
    fi
    if [ -s $file ]; then
      iskip=0
      (( nfile = nfile + 1 ))
    fi
    echo " cfipg(2)='${file}'," >>namin_rfbias_${nfhrs}
    echo " iskip(2)=${iskip},"  >>namin_rfbias_${nfhrs}
    echo " nfiles=$nfile,"      >>namin_rfbias_${nfhrs}

    file=rfbias_0p50.${MD}00.f${nfhrs}
    echo " cfopg1='${file}',"   >>namin_rfbias_${nfhrs}
    echo " /" >>namin_rfbias_${nfhrs}
  fi

done

if [ -s poescript_avggen_rfbias ]; then
  rm poescript_avggen_rfbias
fi

for nfhrs in $hourlist; do
  rem=`echo "${nfhrs}%6" | bc`
  if [ $rem -eq 0 ]; then
    file=rfbias_0p50.${MD}00.f${nfhrs}
    echo "$nfhrs is even number, no need to calculate reforecast bias"
  else
    echo "$EXECgefs/${pgm} <namin_rfbias_${nfhrs} > $pgmout.rfbias.${nfhrs}" >> poescript_avggen_rfbias
  fi
done

if [ -s poescript_avggen_rfbias ]; then
  chmod +x poescript_avggen_rfbias
  startmsg
  $APRUN poescript_avggen_rfbias
  export err=$?; err_chk
  wait
fi

set +x
echo " "
echo "Leaving sub script gefs_bias_reforecast.sh"
echo " "
set -x

