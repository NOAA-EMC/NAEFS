#if [ $# -ne 2 ] ; then
#echo "Usage: $0 need input CDATE and (or) gefs/naefs "
#exit 1
#fi
#set -eu

#CDATE=$1
#run=$2

CDATE=2014012700
run=naefs

#COM=/ptmp/Bo.Cui/com/gens/wcoss
#COM=/com/gens/prod 
#COM=$NGLOBAL/Bo.Cui/com/gens/para 

YMD=`echo $CDATE | cut -c1-8`
CYC=`echo $CDATE | cut -c9-10`

fdir=$COM/$run.$YMD/$CYC/pgrba_bc

echo " prod 18432(per 3072) records, para 19200(per 3200) records "
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

    file=$fdir/$px$prod.t${CYC}z.pgrba_bcf$hr
    line=`wgrib -PDS10 $file | grep " $IDS " | wc -l`
    #line=`wgrib -PDS10 $file | wc -l`
    tline=`expr $tline + $line`
    echo "$px$prod.t${CYC}z.pgrba_bcf$hr has records of $line"
    done
    echo " "
    echo "###### total records of $prod are $tline ######"
    echo " "

    lines=`expr $lines + $tline`
done

echo "SUMMARY OF $YMD $CYC ($run): TOTAL RECORDS = $lines "

echo " "
echo " prod 18432(per 3072) records, para 19200(per 3200) records "
echo " "
