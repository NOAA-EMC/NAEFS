
hourlist="     06  12  18  24  30  36  42  48  54  60  66  72  78  84  90  96 
          102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
          204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

memberlist="c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"

#CDATE=2014012700
ndays=1
iday=1

#COM=/ptmp/Bo.Cui/com/gens/wcoss 
#COM=/com/gens/prod  

while [ $iday -le $ndays ]; do

  PDY=`echo $CDATE | cut -c1-8`
  cyc=`echo $CDATE | cut -c9-10`

  echo " day " $PDY$cyc

  ymdh=`$NDATE -24 $CDATE`
  PDYm1=`echo ${ymdh} | cut -c1-8`
  ymdh=`$NDATE -48 $CDATE`
  PDYm2=`echo ${ymdh} | cut -c1-8`
  ymdh=`$NDATE -72 $CDATE`
  PDYm3=`echo ${ymdh} | cut -c1-8`

  COMINCMC=$COM/cmce.$PDY/$cyc
  COMINCMCm1=$COM/cmce.$PDYm1/$cyc
  COMINCMCm2=$COM/cmce.$PDYm2/$cyc
  COMINCMCm3=$COM/cmce.$PDYm3/$cyc

  echo $COMINCMC
  if [ $cyc -eq 00 -o $cyc -eq 12 ]; then

    echo " CMC ensstat 31@00z 30@12z "
    ls $COMINCMC/ensstat | wc
    echo " "

#   echo " CMC pgrb2ap5 data 2230, or 2232 @PDYm2 (*anl* and cmc_gbanl*)"
    echo " CMC pgrb2ap5 data 4462, or 4464 @PDYm2 (*anl* and cmc_gbanl*)"
    echo " CMC pgrb2ap5 data 7408 for every Thursday"                          
    ls $COMINCMC/pgrb2ap5 | wc
    echo " "

    echo " CMC pgrb2ap5_an data 2037 "
    ls $COMINCMC/pgrb2ap5_an | wc
    echo " "

    echo " CMC pgrb2ap5_wt data 2037 "
    ls $COMINCMC/pgrb2ap5_wt | wc
    echo " "

    echo " new dir CMC pgrb2ap5_bc 194 "
    ls $COMINCMC/pgrb2ap5_bc | wc
    echo " "

    echo " extend forecats 00z 1472 without  idx "
  fi

  if [ $cyc -eq 06 -o $cyc -eq 18 ]; then

#   echo " CMC ensstat 0 "
#   ls $COMINCMC/ensstat | wc
#   echo " "

#   echo " CMC pgrb2a 0 "
#   ls $COMINCMC/pgrb2ap5 | wc
#   echo " "

    echo " CMC pgrb2ap5 2 or 1 "
    ls $COMINCMCm1/pgrb2ap5 | wc
    echo " "

  fi 

  echo " CMC glbanl 1 "
  ls $COMINCMCm2/pgrb2ap5/cmc_glbanl.t${cyc}z.pgrb2a.0p50_mdf000 | wc
  echo " "

  echo " CMC anl 1 "
  ls $COMINCMCm1/pgrb2ap5/cmc_gec00.t${cyc}z.pgrb2a.0p50.anl     | wc
  echo " "

  iday=`expr $iday + 1`
  CDATE=`$NDATE +06 $CDATE`

done


