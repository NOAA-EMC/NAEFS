set -x 

###########################################################
# naefs using module compile standard
# 08/06/2021 Bo.Cui@noaa.gov:    Create module load version
###########################################################

module purge
moduledir=`dirname $(readlink -f ../modulefiles/NAEFS)`
source ../versions/build.ver
module use ${moduledir}
#source  ${moduledir}/NAEFS/${naefs_ver}
module load NAEFS/${naefs_ver}
module list

export INC="${G2_INC4} "
export FC=ftn
export FFLAGS="-O3 -g -convert big_endian -I ${G2_INC4}"

export LIBS="${G2_LIB4} ${W3NCO_LIB4} ${BACIO_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB}"

#for dir in *.fd;  do
for dir in gefs_bias_combine.fd;  do
 cd $dir
 make clean
 make -f makefile
 cd ..
done
