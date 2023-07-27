CDATE=2023020400

run=gefs

#COM=/lfs/h1/ops/prod/com/naefs/v6.1
COM=/lfs/h2/emc/ptmp/bo.cui/com/naefs/v7.0

YMD=`echo $CDATE | cut -c1-8`
CYC=`echo $CDATE | cut -c9-10`

fdir=$COM/$run.$YMD/$CYC/prcp_gb2   

echo " "

px=ge   
hourlist="    003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 \
          051 054 057 060 063 066 069 072 075 078 081 084 087 090 093 096 099 \
          102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 \
          153 156 159 162 165 168 171 174 177 180 183 186 189 192 198 204 \
          210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

#hourlist="024 120 "

#### 1. for prcp_gb2

lines=0
for prod in pqpf; do

  tline=0
  for hr in $hourlist; do
    file=$fdir/$px$prod.t${CYC}z.pgrb2a.0p50.24hf$hr
    if [ -s $file ]; then
      line=`$WGRIB2 $file | grep "APCP" | wc -l`
      tline=`expr $tline + $line`
#     echo "$px$prod.t${CYC}z.pgrb2a.0p50.24hf$hr has records of $line"
    fi 
  done

  lines=`expr $lines + $tline`
done

echo " "
echo "###### total records for one cycle v6.1 793, v7.0 793 ######"
echo " "

echo " prcp_gb2: TOTAL RECORDS = $lines "

if [ $lines -ne 793 ]; then
  echo $PDY$cyc
  echo "Warning GEFS prcp_gb2 has 793 records"
  echo $lines
fi

#### 2. for prcp_bc_gb2

fdir=$COM/$run.$YMD/$CYC/prcp_bc_gb2   

lines=0
for inter in 06h 24h ; do
for prod in pqpf prcp; do

  tline=0
  for hr in $hourlist; do
    file=$fdir/$px$prod.t${CYC}z.pgrb2a.0p50.bc_${inter}f$hr
    if [ -s $file ]; then
      line=`$WGRIB2 $file | grep "APCP" | wc -l`
      tline=`expr $tline + $line`
#     echo "$px$prod.t${CYC}z.pgrb2a.0p50.bc_${inter}f$hr has records of $line"
    fi 
  done

  lines=`expr $lines + $tline`
done
done

for prod in prcp; do
for var in anv efi; do
  tline=0
  for hr in $hourlist; do
    file=$fdir/$px$prod.t${CYC}z.pgrb2a.0p50.${var}f$hr
    if [ -s $file ]; then
      line=`$WGRIB2 $file | grep "APCP" | wc -l`
      tline=`expr $tline + $line`
#     echo "$px$prod.t${CYC}z.pgrb2a.0p50.${var}f$hr has records of $line"
    fi 
  done
  lines=`expr $lines + $tline`
done
done

echo
echo "###### total records for one cycle v6.1 4662, v7.0 5912 ######"
echo

echo "prcp_bc_gb2: TOTAL RECORDS = $lines "

if [ $lines -ne 5912 ]; then
  echo $PDY$cyc
  echo "Warning GEFS prcp_bc_gb2 has 4912 records"
  echo $lines
fi


#### 3. for ndgd_prcp_gb2

fdir=$COM/$run.$YMD/$CYC/ndgd_prcp_gb2 

lines=0
for inter in 06h 24h ; do
for prod in pqpf prcp; do

  tline=0
  for hr in $hourlist; do
    file=$fdir/$px$prod.t${CYC}z.ndgd2p5_conus.${inter}f$hr.gb2
    if [ -s $file ]; then
      line=`$WGRIB2 $file | grep "APCP" | wc -l`
      tline=`expr $tline + $line`
#     echo "$px$prod.t${CYC}z.pgrb2a.0p50.bc_${inter}f$hr has records of $line"
    fi 
  done

  lines=`expr $lines + $tline`
done
done

echo
echo "###### total records for one cycle v6.1 4250, v7.0 5500 ######"
echo

echo "ndgd_prcp_gb2: TOTAL RECORDS = $lines "

if [ $lines -ne 5500 ]; then
  echo $PDY$cyc
  echo "Warning GEFS ndgd_prcp_gb2 has 5500 records"
  echo $lines
fi
