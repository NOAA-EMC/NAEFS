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

nhoursx=/nwprod/util/exec/ndate

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

  COMIN=$COM/gefs.$PDY/$cyc
  COMINm1=$COM/gefs.$PDYm1/$cyc
  COMINm2=$COM/gefs.$PDYm2/$cyc

### 

# echo " dir GEFS pgrb2ap5_bc 5348, without prob fcst 4194 (21*194+122)  "
  echo " dir GEFS pgrb2ap5_bc 7288, without prob fcst 6136 (31*194+122)  "

  ls $COMIN/pgrb2ap5_bc | wc
  echo " "

output="$( bash <<EOF
  ls $COMIN/pgrb2ap5_bc | wc -l
EOF
)"
  if [ $output -ne 7288 -a $output -ne 6136 ]; then
    echo $PDY$cyc
    echo "Warning !!! GEFS bc has file 7288 or 6136 files"
    echo $output
  fi

###

# echo " GEFS pgrb2ap5_an data 2098 (21*97+61), avg(+192) efi(+96) total 2386 "
  echo " GEFS pgrb2ap5_an data 3068 (31*97+61), avg(+192) efi(+96) total 3356 "
  ls $COMIN/pgrb2ap5_an | wc
  echo " "

output="$( bash <<EOF
  ls $COMIN/pgrb2ap5_an | wc -l
EOF
)"
  if [ $output -ne 3068  -a $output -ne 3356 ]; then
    echo $PDY$cyc
    echo "Warning !!! GEFS an has file 3356 files"
    echo $output
  fi

###
### 

# echo " GEFS pgrb2ap5_wt data 2037 ( 21*97) "
  echo " GEFS pgrb2ap5_wt data 3007 ( 31*97) "
  ls $COMIN/pgrb2ap5_wt | wc
  echo " "

output="$( bash <<EOF
  ls $COMIN/pgrb2ap5_wt | wc -l
EOF
)"
  if [ $output -ne 3007 ]; then
    echo $PDY$cyc
    echo "Warning !!! GEFS wt has file 3007 files"
    echo $output
  fi

### 

  echo " 1 degree "

# echo " dir GEFS pgrb2a_bc 2098, with prob fcst 2674 ( add 96*6)  "
  echo " dir GEFS pgrb2a_bc 3068, with prob fcst 3644 ( add 96*6)  "

###
  ls $COMIN/pgrb2a_bc | wc
  echo " "

output="$( bash <<EOF
  ls $COMIN/pgrb2a_bc | wc -l
EOF
)"
  if [ $output -ne 3068 -a $output -ne 3644 ]; then
    echo $PDY$cyc
    echo "Warning !!! GEFS bc 1 degree has file 3068 or 3644 files"
    echo $output
  fi

###

# echo " GEFS pgrb2a_an data 2098, 2290 with avg "
  echo " GEFS pgrb2a_an data 3068, 3260 with avg "
  ls $COMIN/pgrb2a_an | wc
  echo " "

output="$( bash <<EOF
  ls $COMIN/pgrb2a_an | wc -l
EOF
)"
  if [ $output -ne 3068 -a $output -ne 3260 ]; then
    echo $PDY$cyc
    echo "Warning !!! GEFS an 1 degree has file 3068 or 3260 files"
    echo $output
  fi

###

  echo " GEFS ndgd_gb2 prod 1152, 1154 with dv "
  ls $COMIN/ndgd_gb2 | wc
  echo " "

output="$( bash <<EOF
  ls $COMIN/ndgd_gb2  | wc -l
EOF
)"
  if [ $output -ne 1152 -a $output -ne 1154 ]; then
    echo $PDY$cyc
    echo "Warning !!! GEFS ndgd has file 1152 or 1154 files"
    echo $output
  fi

###

  echo " GEFS pgrb2ap5 me 157, mecom 96, bar 320, r2 96 "

  ls $COMIN/pgrb2ap5/*mef* | wc
  ls $COMIN/pgrb2ap5/*mecomf* | wc
  ls $COMIN/pgrb2ap5/*bar* | wc
  ls $COMIN/pgrb2ap5/*coeff* | wc

  echo " "
  echo " GEFS pgrb2ap5 total 671  "
# echo " GEFS pgrb2ap5 avg 97, c00 97, gfs 85, anl 2, mdf 2 "

  ls $COMIN/pgrb2ap5/* | wc

  echo " "

# echo " GEFS prcp_gb2 prod 61, para 61 "
# ls $COMIN/prcp_gb2 | wc
# echo " "

# echo " GEFS prcp prod 61, para 61 "
# ls $COMIN/prcp | wc
# echo " "

  echo " GEFS glbanl 1 "
  ls $COMINm1/pgrb2ap5/glbanl.t${cyc}z.pgrb2a.0p50_mdf000 | wc
  echo " "

  echo " NCEP CMC glbanl 1 "
  ls $COMINm2/pgrb2ap5/ncepcmc_glbanl.t${cyc}z.pgrb2a.0p50_mdf000 | wc
  echo " "

  echo " NCEP FNMOC glbanl 1 "
  ls $COMINm1/pgrb2a/ncepfnmoc_glbanl.t${cyc}z.pgrb2a_mdf00 | wc
  echo " "

  echo " NCEP dv at 03 09 15 21 "
  ls $COM/gefs.$PDYm1/03/ndgd_gb2 | wc
  ls $COM/gefs.$PDYm1/09/ndgd_gb2 | wc
  ls $COM/gefs.$PDYm1/15/ndgd_gb2 | wc
  ls $COM/gefs.$PDYm1/21/ndgd_gb2 | wc
  echo " "

  iday=`expr $iday + 1`
  CDATE=`$NDATE +06 $CDATE`

done


