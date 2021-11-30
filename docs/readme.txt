NAEFS v6.0.0 Implementation Instructions:

1. Checkout svn tags:

https://svnemc.ncep.noaa.gov/trac/naefs/browser/tags/naefs.v6.0.0

2. Set up the package

   copy this directory to naefs.v6.0.0 "(your file location)"

  (2) Build the executables of NAEFS
      Go to the sorc sub-directory, following the instructions in README.build file,
      all the executables will be generated and saved in the exec sub-directory.

3. Start the test run on cray
   Please check and modify (if it is necessary) the ecf and job files in sub-directory
   ecf and jobs, to make sure the paths of the source and output files are correct.
  
4. Resources requirements

  (1) Compute resource information:
      Computer: Current need around 10 nodes; future will need more nodes 
      Please check the ecf sub-directory, the computer resource requirement
      can be found in each jobs' ecf file

  (2) Disk space
      Main change happen for new directories pgrb2ap5_bc, pgrb2ap5_an, pgrb2ap5_wt
      - new pgrb2ap5_bc: 22GB, 0.5d bias corrected forecasts (3 hourly for day 8)
      - new pgrb2ap5_an: 10GB, 0.5d anomaly forecast
      - new pgrb2ap5_wt: 500mb, 0.5d weight for each member
      - prcp_gb2: 1GB, 0.5d bias corrected prcp
      - new ndgd_prcp_gb2: 1GB, 2.5km bias corrected and downscaled prcp for CONUS

5. New Products

   GEFS 0.5d bias corrected forecasts, 0.5d anomaly forecasts

  (1) File names for GEFS bias corrected products  
      GEFS filenames pgrb2ap5_bc/ge###.t##z.pgrb2a.0p50_bcf###                

  (2) File names for GEFS anomaly forecast  
      GEFS filenames pgrb2ap5_an/ge###.t##z.pgrb2a.0p50_anf###                

  (3) File names for GEFS anomaly forecast for ensemble average 
      GEFS filenames pgrb2ap5_an/geavg.t##z.pgrb2a.0p50_anf###                

  (4) File names for GEFS EFI 
      GEFS filenames pgrb2ap5_an/geefi.t##z.pgrb2a.0p50_bcf###                

  (5) File names for GEFS bias weight for each ensemble member 
      GEFS filenames pgrb2ap5_wt/ge###.t##z.pgrb2a.0p50_wtf###                

  (6) File names for ensemble based PQPF forecast
      GEFS filenames prcp_gb2/gepqpf.tCCz.pgrb2a.0p50.24hf###                 

  (7) File names for ensemble quantitative precipitation forecast
      GEFS filenames prcp_bc_gb2/geprcp.t##z.pgrb2a.0p50.bc_24hf###           
                     prcp_bc_gb2/geprcp.t##z.pgrb2a.0p50.bc_06hf###
                     prcp_bc_gb2/gepqpf.t##z.pgrb2a.0p50.bc_24hf###
                     prcp_bc_gb2/gepqpf.t##z.pgrb2a.0p50.bc_06hf###

  (8) File names for extreme precipitation forecast                     
      GEFS filenames prcp_bc_gb2/geprcp.t##z.pgrb2a.0p50.anvf###              
                     prcp_bc_gb2/geprcp.t##z.pgrb2a.0p50.efif###

  (9) File names for quantitative precipitation forecast for CONUS       
      GEFS filenames ndgd_prcp_gb2/geprcp.t##z.ndgd2p5_conus.24hf###.gb2      
                     ndgd_prcp_gb2/geprcp.t##z.ndgd2p5_conus.06hf###.gb2
                     ndgd_prcp_gb2/gepqpf.t##z.ndgd2p5_conus.24hf###.gb2
                     ndgd_prcp_gb2/gepqpf.t##z.ndgd2p5_conus.06hf###.gb2


   CMC 0.5d raw and bias corrected forecasts

  (1) File names for CMC raw ensmeble forecast
      CMC filenames pgrb2ap5/cmc_ge###.t##z.pgrb2a.0p50.f###                

  (2) File names for CMC bias corrected ensmeble forecast
      CMC filenames pgrb2ap5_bc/cmc_ge###.t##z.pgrb2a.0p50_bcf###                

   NAEFS 0.5d bias corrected forecasts

  (1) File names for NAEFS EFI 
      GEFS filenames pgrb2ap5_an/naefs_geefi.t##z.pgrb2a.0p50_bcf###                

6. Copy files from para to prod directory before implementation
   cd /nwprod/naefs.v6.0.0/util/imp_util/run_para_to_prod
   vi run_copy_para_to_prod and set "CDATE=2016020106"
   ./run_copy_para_to_prod


