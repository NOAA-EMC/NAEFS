#COM=/com/gens/prod

############################################
# 1. 1780: pgrba_bcf
# 2. 1460: pgrba_an
# 3. 1365: pgrba_wt
# 4. 3586: pgrba
# 9 64 naefs_geavg.t${cyc}z.ndgd_conus*    
#10 64 naefs_geavg.t${cyc}z.ndgd_conus*

############################################

hourlist="     06  12  18  24  30  36  42  48  54  60  66  72  78  84  90  96 
          102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
          204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

memberlist="c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"

#CDATE=2014012300
#CDATE=$1
ndays=1
iday=1

while [ $iday -le $ndays ]; do

  PDY=`echo $CDATE | cut -c1-8`
  cyc=`echo $CDATE | cut -c9-10`

  echo " day " $PDY$cyc

  ymdh=`$NDATE -24 $CDATE`
  PDYm1=`echo ${ymdh} | cut -c1-8`
  ymdh=`$NDATE -48 $CDATE`
  PDYm2=`echo ${ymdh} | cut -c1-8`

  COMIN=$COM/naefs.$PDY/$cyc
  COMINm1=$COM/naefs.$PDYm1/$cyc
  COMINm2=$COM/naefs.$PDYm2/$cyc

###

  echo " naefs pgrb2ap5_bc 576 "
  ls $COMIN/pgrb2ap5_bc | wc
  echo " "

output="$( bash <<EOF
  ls $COMIN/pgrb2ap5_bc | wc -l
EOF
)"
  if [ $output -ne 576 ]; then
    echo $PDY$cyc
    echo "Warning !!! NAEFS bc has file 576 files"
    echo $output
  fi

###

  echo " naefs pgrb2ap5_an data 288 (3*96)"
  ls $COMIN/pgrb2ap5_an | wc
  echo " "

output="$( bash <<EOF
  ls $COMIN/pgrb2ap5_an | wc -l
EOF
)"
  if [ $output -ne 288 ]; then
    echo $PDY$cyc
    echo "Warning !!! NAEFS an has file 288 files"
    echo $output
  fi

###

  echo " naefs pgrb2a_bc 576 "
  ls $COMIN/pgrb2a_bc | wc
  echo " "

output="$( bash <<EOF
  ls $COMIN/pgrb2a_bc | wc -l
EOF
)"
  if [ $output -ne 576 ]; then
    echo $PDY$cyc
    echo "Warning !!! NAEFS bc 1 degree has file 576 files"
    echo $output
  fi

###

  echo " naefs pgrb2a_an data 192 (2*96)"
  ls $COMIN/pgrb2a_an | wc
  echo " "

output="$( bash <<EOF
  ls $COMIN/pgrb2a_an | wc -l
EOF
)"
  if [ $output -ne 192 ]; then
    echo $PDY$cyc
    echo "Warning !!! NAEFS an 1 degree has file 192 files"
    echo $output
  fi

###

  echo " naefs ndgd_gb2 1154 ( 2*576+2)"
  ls $COMIN/ndgd_gb2 | wc
  echo " "

output="$( bash <<EOF
  ls $COMIN/ndgd_gb2  | wc -l
EOF
)"
  if [ $output -ne 1154 ]; then
    echo $PDY$cyc
    echo "Warning !!! NAEFS ndgd has file 1154 files"
    echo $output
  fi

###

  iday=`expr $iday + 1`
  CDATE=`$NDATE +06 $CDATE`

done


