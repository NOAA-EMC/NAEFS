
#COM=/com/gens/prod

############################################
# 1 65 fnmoc_geavg.t${cyc}z.pgrba*
# 2 65 fnmoc_gespr.t${cyc}z.pgrba*
# 3 65 fnmoc_geavg.t${cyc}z.pgrba_mef*
# 4 1  fnmoc_geavg.t${cyc}z.pgrba_mef*
# 5 1  ncepfnmoc_glbanl.t${cyc}z.pgrba_mdf00

# 6 64 fnmoc_geavg.t${cyc}z.pgrba_bcf*
# 7 64 fnmoc_gespr.t${cyc}z.pgrba_bcf*
# 7 64 fnmoc_gec00.t${cyc}z.pgrba_bcf*
# 8 1280 fnmoc_gep*.t${cyc}z.pgrba_bcf*
# 8 1344 fnmoc_gep*.t${cyc}z.pgrba_an*
# 8 1344 fnmoc_gep*.t${cyc}z.pgrba_wt*

# 9 64 naefs_geavg.t${cyc}z.ndgd_conus*    
#10 64 naefs_geavg.t${cyc}z.ndgd_conus*

############################################

hourlist="    003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 \
          051 054 057 060 063 066 069 072 075 078 081 084 087 090 093 096 099 \
          102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 \
          153 156 159 162 165 168 171 174 177 180 183 186 189 192 198 204 \
          210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

memberlist="c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"

#CDATE=2014012300
#CDATE=$1
ndays=1
iday=1

echo $CDATE
while [ $iday -le $ndays ]; do

  PDY=`echo $CDATE | cut -c1-8`
  cyc=`echo $CDATE | cut -c9-10`

  echo " day " $PDY$cyc

  ymdh=`$NDATE -24 $CDATE`
  PDYm1=`echo ${ymdh} | cut -c1-8`
  ymdh=`$NDATE -48 $CDATE`

  COMIN=$COM/fens.$PDY/$cyc
  COMINm1=$COM/fens.$PDYm1/$cyc

  if [ $cyc -eq 00 -o $cyc -eq 12 ]; then

    echo " dir FNMOC pgrb2ap5_bc prod 2560, para 2816 para 194 ( 97*2) "
    ls $COMIN/pgrb2ap5_bc | wc
    echo " "

output="$( bash <<EOF
  ls $COMIN/pgrb2ap5_bc  | wc -l
EOF
)"
  if [ $output -ne 194 ]; then
    echo $PDY$cyc
    echo "Warning !!! FNMOC pgrb2ap5_bc has 194 files"
    echo $output
  fi

    echo " new dir FNMOC pgrb2ap5_an data prod 0, para 1344 new 2037 "
    ls $COMIN/pgrb2ap5_an | wc
    echo " "

output="$( bash <<EOF
  ls $COMIN/pgrb2ap5_an  | wc -l
EOF
)"
  if [ $output -ne 2037 ]; then
    echo $PDY$cyc
    echo "Warning !!! FNMOC pgrb2ap5_an has 2037 files"
    echo $output
  fi

    echo " new dir FNMOC pgrb2ap5_wt data prod 0, para 1344 new 2037 "
    ls $COMIN/pgrb2ap5_wt | wc
    echo " "

output="$( bash <<EOF
  ls $COMIN/pgrb2ap5_wt  | wc -l
EOF
)"
  if [ $output -ne 2037 ]; then
    echo $PDY$cyc
    echo "Warning !!! FNMOC pgrb2ap5_wt has 2037 files"
    echo $output
  fi

    echo " New dir FNMOC pgrb2ap5 prod 0, para 191 para 195/194 "
    ls $COMIN/pgrb2ap5 | wc
    echo " "

output="$( bash <<EOF
  ls $COMIN/pgrb2ap5  | wc -l
EOF
)"
  if [ $output -ne 194  -a $output -ne 195 ]; then
    echo $PDY$cyc
    echo "Warning !!! FNMOC pgrb2ap5 has 194/195 files"
    echo $output
  fi

  fi

  if [ $cyc -eq 06 -o $cyc -eq 18 ]; then

    echo "  New dir FNMOC pgrb2a prod 0, para pgrb2ap5 1 "
    ls $COMINm1/pgrb2ap5 | wc
    echo " "

output="$( bash <<EOF
  ls $COMINm1/pgrb2ap5  | wc -l
EOF
)"
  if [ $output -ne 1 ]; then
    echo $PDY$cyc
    echo "Warning !!! FNMOC glbanl has 1 file"
    echo $output
  fi

  fi

  echo " FNMOC glbanl 1 fnmoc_glbanl* "
  ls $COMINm1/pgrb2ap5/fnmoc_glbanl.t${cyc}z.pgrb2a.0p50_mdf000 | wc
  echo " "

  COMINm1=$COM/gefs.$PDYm1/$cyc
  echo " NCEP FNMOC glbanl 1 ncepfnmoc_glbanl* "
  ls $COMINm1/pgrb2ap5/ncepfnmoc_glbanl.t${cyc}z.pgrb2a.0p50_mdf000 | wc
  echo " "

  iday=`expr $iday + 1`
  CDATE=`$NDATE +06 $CDATE`

done


