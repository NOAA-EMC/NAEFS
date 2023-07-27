#COM=/lfs/h1/ops/prod/com/naefs/v6.1
#COM=/lfs/h2/emc/ptmp/$LOGNAME/com/naefs/v7.0

#CDATE=2023020400
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

  echo " dir GEFS prcp_gb2 61 "

  ls $COMIN/prcp_gb2 | wc
  echo " "

output="$( bash <<EOF
  ls $COMIN/prcp_gb2 | wc -l
EOF
)"
  if [ $output -ne 61 ]; then
    echo $PDY$cyc
    echo "Warning !!! GEFS prcp_gb2 has file 61"
    echo $outpu
  fi

###

  echo " GEFS prcp_bc_gb2 data 378 "
  ls $COMIN/prcp_bc_gb2 | wc
  echo " "

output="$( bash <<EOF
  ls $COMIN/prcp_bc_gb2 | wc -l
EOF
)"
  if [ $output -ne 378 ]; then
    echo $PDY$cyc
    echo "Warning !!! GEFS prcp_bc_gb2 has file 378 files"
    echo $output
  fi

###

  echo " GEFS ndgd_prcp_gb2 data 250 "
  ls $COMIN/ndgd_prcp_gb2 | wc
  echo " "

output="$( bash <<EOF
  ls $COMIN/ndgd_prcp_gb2 | wc -l
EOF
)"
  if [ $output -ne 250 ]; then
    echo $PDY$cyc
    echo "Warning !!! GEFS ndgd_prcp_gb2 has file 250 files"
    echo $output
  fi

###

  COMIN=$COM/gefs.$PDY

  echo " GEFS cqpf gempak data 2732 or 683 per cycle "
  ls $COMIN/gempak/prcp | wc
  echo " "

output="$( bash <<EOF
  ls $COMIN/gempak/prcp | wc -l
EOF
)"
  if [ $output -ne 2732  -a $output -ne 683 ]; then
    echo $PDY$cyc
    echo "Warning !!! GEFS cqpf gempak has file 2732 or 683 files"
    echo $output
  fi

  iday=`expr $iday + 1`
  CDATE=`$NDATE +06 $CDATE`

done


