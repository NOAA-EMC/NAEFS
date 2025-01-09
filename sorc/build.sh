#!/bin/bash

################################################################################
### Usage:
###
### To build, install, and clean all executables
###  ./build.sh all >& naefs.compile.log
###
### To build, install, and clean a specific executable for name_exec.fd
###    ./build.sh name_exec all >& naefs.compile.log
###
### To build install, and clean all executables in debug mode
###    ./build.sh debug >& naefs.compile.log
###
### To build, install, and clean a specific executable in debug mode name_exec
###    ./build.sh name_exec debug all >& naefs.compile.log
###
### More information at file sorc/README.build
###
################################################################################

# Enable debugging and exit on errors
set -x -e

# Define the executable directory and create it if it doesn't exist
EXECdir=../exec
[ -d $EXECdir ] || mkdir $EXECdir

# Define the logs directory and create it if it doesn't exist
logs_dir="logs"
if [[ ! -d "${logs_dir}" ]]; then
  echo "Creating logs folder"
  mkdir -p "${logs_dir}" || exit 1
fi

# Log file based on the executable and action (build, install, clean)
#log_file="${logs_dir}/build_$(date +'%Y%m%d_%H%M%S').log"

if [ ! -z "$2" ]; then
  log_file="${logs_dir}/build_$1_$2.log"
else
  log_file="${logs_dir}/build_$1.log"
fi

# Redirect both stdout and stderr to the log file
exec > >(tee -a "${log_file}") 2>&1

# Load necessary modules and set environment variables
module purge
moduledir=$(dirname $(readlink -f ../modulefiles/NAEFS))
source ../versions/build.ver
module use ${moduledir}
module load NAEFS/${naefs_ver}
module list

export INC="${G2_INC4} "
export FC=ftn

# Default compiler flags
FFLAGS="-O3 -g -convert big_endian -traceback"

# Debug flags
DEBUG="-check all -ftrapuv"

# Check if we are building debug executables
if [ "$1" == "debug" ] || [ "$2" == "debug" ]; then
  # Append debug flags to FFLAGS
  export FFLAGS="${FFLAGS} ${DEBUG} -I ${INC}"
  echo "Building in debug mode"
else
  # For non-debug builds, just append the include directory to FFLAGS
  export FFLAGS="${FFLAGS} -I ${INC}"
fi

export LIBS="${G2_LIB4} ${W3NCO_LIB4} ${BACIO_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB}"

# Function to build, install, and clean executables

build_all_execs() {
    for dir in *.fd; do
        if [ -d "$dir" ]; then
            echo "Building in directory: $dir"
            cd $dir
            make clean
            make -f makefile
            if [ $? -ne 0 ]; then
              echo "ERROR: build of $dir FAILED!"
            fi
            cd ..
        fi
    done
}

install_all_execs() {
    for dir in *.fd; do
        if [ -d "$dir" ]; then
            echo "Installing in directory: $dir"
            cd $dir
            make install
            if [ $? -ne 0 ]; then
              echo "ERROR: install of $dir FAILED!"
            fi
            cd ..
        fi
    done
}

clean_all_execs() {
    for dir in *.fd; do
        if [ -d "$dir" ]; then
            echo "Cleaning directory: $dir"
            cd $dir
            make clean
            if [ $? -ne 0 ]; then
              echo "ERROR: clean of $dir FAILED!"
            fi
            cd ..
        fi
    done
}

# Build, Install, Clean individual executable

build_individual_exec() {
    local exec_dir=$1
    if [ -d "$exec_dir.fd" ]; then
        echo "Building individual exec: $exec_dir"
        cd $exec_dir.fd
        make clean
        make -f makefile
        if [ $? -ne 0 ]; then
          echo "ERROR: build of $exec_dir FAILED!"
        fi
        cd ..
    else
        echo "Directory $exec_dir.fd does not exist."
        exit 1
    fi
}

install_individual_exec() {
    local exec_dir=$1
    if [ -d "$exec_dir.fd" ]; then
        echo "Installing individual exec: $exec_dir"
        cd $exec_dir.fd
        make install
        cd ..
    else
        echo "Directory $exec_dir.fd does not exist."
        exit 1
    fi
}

clean_individual_exec() {
    local exec_dir=$1
    if [ -d "$exec_dir.fd" ]; then
        echo "Cleaning individual exec: $exec_dir"
        cd $exec_dir.fd
        make clean
        cd ..
    else
        echo "Directory $exec_dir.fd does not exist."
        exit 1
    fi
}

# Parse options
case $1 in
    "all")
        # Build, install, and clean all executables
        build_all_execs
        install_all_execs
        clean_all_execs
        ;;
    "build")
        # Only build all executables
        build_all_execs
        ;;
    "install")
        # Only install all executables
        install_all_execs
        ;;
    "clean")
        # Only clean all executables
        clean_all_execs
        ;;
    "debug")
        # Build, install, and clean all executables in debug mode
        build_all_execs
        install_all_execs
        clean_all_execs
        ;;
    *)
        # Check for individual executable commands
        if [ ! -z "$1" ]; then
            # If an individual exec name is provided
            if [ "$2" == "build" ]; then
                build_individual_exec $1
            elif [ "$2" == "install" ]; then
                install_individual_exec $1
            elif [ "$2" == "clean" ]; then
                clean_individual_exec $1
            elif [ "$2" == "all" ]; then
                build_individual_exec $1
                install_individual_exec $1
                clean_individual_exec $1
            elif [ "$2" == "debug" ]; then
                if [ ! -z "$3" ]; then
                   if [ "$3" == "all" ]; then
                       build_individual_exec $1
                       install_individual_exec $1
                       clean_individual_exec $1
                   elif [ "$3" == "build" ]; then
                       build_individual_exec $1
                   elif [ "$3" == "install" ]; then
                       install_individual_exec $1
                   elif [ "$3" == "clean" ]; then
                       clean_individual_exec $1
                   else
                     echo "Error, Unknown option. Use build, install, or clean with an individual exec."
                     exit 1
                   fi
                fi
            else
                echo "Error, Unknown option. Use build, install, or clean with an individual exec."
                exit 1
            fi
        else
            echo "Usage: $0 {all|build|install|clean|debug} [exec_name] {build|install|clean}"
            exit 1
        fi
        ;;
esac

