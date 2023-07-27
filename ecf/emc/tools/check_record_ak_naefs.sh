#if [ $# -ne 2 ] ; then
#echo "Usage: $0 need input CDATE and (or) gefs/naefs "
#exit 1
#fi
#set -eu

#CDATE=$1
#run=$2

#CDATE=2014102706
run=naefs

#COM=$NGLOBAL/Bo.Cui/com/gens/para 
#COM=/com/parallel-test/20141020/com/gens/prod
#COM=/com/gens/prod 

YMD=`echo $CDATE | cut -c1-8`
CYC=`echo $CDATE | cut -c9-10`

fdir=$COM/$run.$YMD/$CYC/ndgd

echo " forecast hour  06 12 18 24 30 36 42 48 54 60" 
echo " ak para recode  8  8  8  9  8  9  8  9  8  9 " 
echo " ak prod recode  6  6  6  7  6  7  6  7  6  7 " 
echo " prod 2490 records, para 3258 records "
echo " "

if [ "$run" = "naefs" ]; then
   px=naefs_
   IDS=114
else
   px=
   IDS=107
fi

lines=0
for prod in gespr gemode geavg ge10pt ge50pt ge90pt
do

    tline=0

    for hr in 06 12 18 24 30 36 42 48 54 60 66 72 78 84 90 96 102 108 114 120 \
    126 132 138 144 150 156 162 168 174 180 186 192 198 204 210 216 222 \
    228 234 240 246 252 258 264 270 276 282 288 294 300 306 312 318 324 \
    330 336 342 348 354 360 366 372 378 384
    do

    file=$fdir/$px$prod.t${CYC}z.ndgd_alaskaf$hr
    line=`wgrib -PDS10 $file | grep " $IDS " | wc -l`
    #line=`wgrib -PDS10 $file | wc -l`
    tline=`expr $tline + $line`
    echo "$px$prod.t${CYC}z.ndgd_alaskaf$hr has records of $line"
    done
    echo " "
    echo "###### total records of $prod are $tline ######"
    echo " "

    lines=`expr $lines + $tline`
done

echo "SUMMARY OF $YMD $CYC ($run): TOTAL RECORDS = $lines "

echo " "
echo " prod 2490 records, para 3258 records for 00z "
echo " para 3252 records for 06z "
echo " "
