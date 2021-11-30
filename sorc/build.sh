#!/bin/sh
set -x -e

###########################################################
# naefs using module compile standard
# 08/06/2021 Bo.Cui@noaa.gov:    Create module load version
###########################################################

machine=${1:-"default"}

if [ -f Module_NAEFS_$machine ]; then
    module purge
    module use .
    source ../versions/build.ver
    source ./Module_NAEFS_$machine
#   module list
else
    echo "machine $machine is not supported"
fi

export INC="${G2_INC4} "
export FC=ftn
#export LIBS_INIT="${SP_LIBd} ${SIGIO_LIB4} ${W3NCO_LIBd}"
#export LIBS_GTRK="${BACIO_LIB4} ${SIGIO_LIB4} ${IP_LIB4} ${SP_LIB4} ${SFCIO_LIB4} ${BUFR_LIB4} ${W3EMC_LIB4} ${W3NCO_LIB4} "
#export FFLAGS="-O3 -g -convert big_endian -I ${G2_INC4} -axCORE-AVX2"
export FFLAGS="-O3 -g -convert big_endian -I ${G2_INC4}"

export LIBS="${G2_LIB4} ${W3NCO_LIB4} ${BACIO_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB}"

for dir in *.fd;  do
 cd $dir
 make clean
 make -f makefile
 cd ..
done
