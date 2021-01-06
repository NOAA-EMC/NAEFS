#!/bin/sh
set -x -e

###########################################################
# naefs using module compile standard
# 06/26/2016 Bo.Cui@noaa.gov:    Create module load version
###########################################################

machine=${1:-"default"}

if [ -f Module_NAEFS_$machine ]; then
    module purge
    module use .
    module load Module_NAEFS_$machine
#   module list
else
    echo "machine $machine is not supported"
fi

export LIBDIR=/gpfs/hps/nco/ops/nwprod/lib
export INCS="${SIGIO_INC4}"
export INCSFC="${SFCIO_INC4}"
export INC="${G2_INC4} "
export INC_d="${G2_INCd}"
export LIBS="${G2_LIB4} ${W3NCO_LIB4} ${BACIO_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB} ${CRAY_IOBUF_POST_LINK_OPTS}"
export LIBS_d="${G2_LIBd} ${W3NCO_LIBd} ${BACIO_LIB4} ${IP_LIBd} ${SP_LIBd} ${PNG_LIB} ${JASPER_LIB} ${Z_LIB} ${W3NCO_LIBd}"
export FC=ftn
export LIBS_INIT="${SP_LIBd} ${SIGIO_LIB4} ${W3NCO_LIBd}"
export LIBS_GTRK="${BACIO_LIB4} ${SIGIO_LIB4} ${IP_LIB4} ${SP_LIB4} ${SFCIO_LIB4} ${BUFR_LIB4} ${W3EMC_LIB4} ${W3NCO_LIB4} "
export FFLAGS="-O3 -g -convert big_endian -I ${G2_INC4} -axCORE-AVX2"
export FFLAGS_d="-O3 -g -r8 -convert big_endian -auto -mkl -I ${G2_INCd} -axCORE-AVX2"

export LIBS="${G2_LIB4} ${W3NCO_LIB4} ${BACIO_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB}"

for dir in *.fd;  do
 cd $dir
 make clean
 make -f makefile
 cd ..
done
