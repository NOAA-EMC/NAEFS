#if [ $# -ne 2 ] ; then
#echo "Usage: $0 need input CDATE and (or) gefs/naefs "
#exit 1
#fi
#set -eu

run=$1

#COM=$NGLOBAL/Bo.Cui/com/gens/para 

YMD=`echo $CDATE | cut -c1-8`
CYC=`echo $CDATE | cut -c9-10`

fdir=$COM/$run.$YMD/$CYC/pgrb2ap5_an

echo " prod 1856 records "
echo " "

if [ "$run" = "naefs" ]; then
   px=naefs_
else
   px=
fi

hourlist="    003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 \
          051 054 057 060 063 066 069 072 075 078 081 084 087 090 093 096 099 \
          102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 \
          153 156 159 162 165 168 171 174 177 180 183 186 189 192 198 204 \
          210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

prodlist="gegfs gec00"

###############
# 1. geavg anv
###############

lines=0
for prod in geavg; do
  tline=0
  for hr in $hourlist; do
    file=$fdir/$px$prod.t${CYC}z.pgrb2a.0p50_anvf$hr
    line=`$WGRIB2 $file | grep "hour " | wc -l`
#   echo $line
    tline=`expr $tline + $line`
#   echo "$px$prod.t${CYC}z.pgrb2a.0p50_anvf$hr has records of $line"
  done
  echo " "
  echo "###### 1. total records of $prod anv are $tline ######"
  echo " "
  lines=`expr $lines + $tline`
done

if [ $lines -ne 1856 ]; then
  echo $PDY$cyc
  echo "Warning GEFS has 1856 records"
  echo $lines
fi


#############
# 2. gec00 an
#############

lines=0
for prod in gec00; do
  tline=0
  for hr in $hourlist; do
    file=$fdir/$px$prod.t${CYC}z.pgrb2a.0p50_anf$hr
    line=`$WGRIB2 $file | grep "hour " | wc -l`
    tline=`expr $tline + $line`
  done
  echo " "
  echo "###### 2. total records of $prod an are $tline ######"
  echo " "
  lines=`expr $lines + $tline`
done

if [ $lines -ne 1856 ]; then
  echo $PDY$cyc
  echo "Warning GEFS has 1856 records"
  echo $lines
fi
##################
# 3. geavg an 
###############

lines=0
for prod in geavg; do
  tline=0
  for hr in $hourlist; do
    file=$fdir/$px$prod.t${CYC}z.pgrb2a.0p50_anf$hr
    line=`$WGRIB2 $file | grep "hour " | wc -l`
    tline=`expr $tline + $line`
#   echo "$px$prod.t${CYC}z.pgrb2a.0p50_anvf$hr has records of $line"
  done
  echo " "
  echo "###### 3. total records of $prod an are $tline ######"
  echo " "
  lines=`expr $lines + $tline`
done

if [ $lines -ne 1856 ]; then
  echo $PDY$cyc
  echo "Warning GEFS has 1856 records"
  echo $lines
fi
##########
# 4. geefi  
##########

echo " "
echo " prod 288 records "
echo " "

lines=0
for prod in geefi; do
  tline=0
  for hr in $hourlist; do
    file=$fdir/$px$prod.t${CYC}z.pgrb2a.0p50_bcf$hr
    line=`$WGRIB2 $file | grep "hour " | wc -l`
#   echo $line
    tline=`expr $tline + $line`
  done
  echo " "
  echo "###### 4. total records of $prod an are $tline ######"
  echo " "
  lines=`expr $lines + $tline`
done

#echo "SUMMARY OF $YMD $CYC ($run): TOTAL RECORDS = $lines "

if [ $lines -ne 288 ]; then
  echo $PDY$cyc
  echo "Warning GEFS has 288 records"
  echo $lines
fi

echo " "

