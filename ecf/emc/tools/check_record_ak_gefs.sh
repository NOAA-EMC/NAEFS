#if [ $# -ne 2 ] ; then
#echo "Usage: $0 need input CDATE and (or) gefs/naefs "
#exit 1
#fi
#set -eu

#CDATE=$1
run=$1
reg=$2

YMD=`echo $CDATE | cut -c1-8`
CYC=`echo $CDATE | cut -c9-10`

fdir=$COM/$run.$YMD/$CYC/ndgd_gb2

echo " forecast hour  06 12 18 24 30 36 42 48 54 60" 
echo " ak prod recode  8  8  8  9  8  9  8  9  8  9 " 
echo " prod 4794 records"
echo " "

if [ "$run" = "naefs" ]; then
   px=naefs 
else
   px=gefs
fi

hourlist="    003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 \
          051 054 057 060 063 066 069 072 075 078 081 084 087 090 093 096 099 \
          102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 \
          153 156 159 162 165 168 171 174 177 180 183 186 189 192 198 204 \
          210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

lines=0
for prod in gespr gemode geavg ge10pt ge50pt ge90pt
do

    tline=0

    for hr in $hourlist; do

    file=$fdir/$px.t${CYC}z.${prod}.f$hr.${reg}.grib2
#   echo $file
#   echo $px.t${CYC}z.${prod}.f$hr.${reg}.grib2
    line=`$WGRIB2 $file | wc -l`
    tline=`expr $tline + $line`
#   echo "$px$prod.t${CYC}z.ndgd_alaskaf$hr has records of $line"
    done
    echo " "
    echo "###### total records of $prod are $tline ######"
    echo " "

    lines=`expr $lines + $tline`
done

if [ $lines -ne 4794 ]; then
  echo $PDY$cyc
  echo "Warning GEFS AK has 4794 records"
  echo $lines 
fi

echo "SUMMARY OF $YMD $CYC ($run): TOTAL RECORDS = $lines "

echo " "
echo " prod 4794 records "
echo " "
