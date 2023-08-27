NAEFS v7.0.0 Implementation Instructions:

1. Checkout NAEFS repository

 https://github.com/NOAA-EMC/NAEFS/tree/develop                        

2. copy fix directory from naefs v6.1.5
    fix files are available at: /lfs/h1/ops/prod/packages/naefs.v6.1.5/fix                  

3. Build the executables of NAEFS
   Go to the sub-directory sorc, following the instructions in README.build file,
   all the executables will be generated and saved in the sub-directory naefs.v7.0.0/exec.

 > cd sorc
 > build.sh
 > install.sh

4. Copy bias files from NAEFS v6 to v7

 > cd ecf/emc/copy-scripts 
 > ./run_copy_para_to_prod
  
   script run_copy_para_to_prod is to copy bias files from v6 to v7.
   change date for CDATEnd run this script. 
