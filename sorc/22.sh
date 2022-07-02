#!/bin/sh
set -x -e

###########################################################
# naefs using module compile standard
# 08/06/2021 Bo.Cui@noaa.gov:    Create module load version
###########################################################

machine=${1:-"default"}

if [ -f Module_NAEFS_$machine ]; then
    module purge
#   module use .
#   source ../versions/build.ver
#   source ./Module_NAEFS_$machine
#   module list
    moduledir=`dirname $(readlink -f ../modulefiles/NAEFS)`
    source ../versions/build.ver
    module use ${moduledir}
    #source  ${moduledir}/NAEFS/${naefs_ver}
    module load NAEFS/${naefs_ver}
    module list
else
    echo "machine $machine is not supported"
fi

export INC="${G2_INC4} "
export FC=ftn
export FFLAGS="-O3 -g -convert big_endian -I ${G2_INC4}"

export LIBS="${G2_LIB4} ${W3NCO_LIB4} ${BACIO_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB}"

for dir in gefs_bias_gen.fd;  do
 cd $dir
 make clean
 make -f makefile
 mv gefs_bias_gen ../../exec/
 cd ..
done
